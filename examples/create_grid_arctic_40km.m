% THIS IS AN EXAMPLE SCRIPT FOR GENERATING A POLAR STEREOGRAPHICAL GRID AND 
%CAN BE USED AS  A TEMPLATE FOR DESIGNING GRIDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Ali Abdolali EMC/NCEP/NOAA ali.abdolali@noaa.gov 26, March 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
clear all 
clc
% 0. Initialization

% 0.a Path to directories 

  bin_dir = '../bin/';             % matlab scripts location
  ref_dir = '../reference_data/';  % reference data location
  out_dir = '../OUTPUT-PATH/';                  % output directory
 
  if exist(out_dir,'dir')~=7
      mkdir (out_dir)
  end
      
% 0.b Design grid parameters

  fname_poly = [ref_dir,'user_polygons.flag']; % File with switches for user 
                                     % defined polygons. An example file 
                                     % has been provided with the reference 
                                     % data for an existing user defined 
                                     % polygon database. A switch of 0 
                                     % ignores the polygon while 1 
                                     % accounts for the polygon.

  fname = 'ArcticStereographic40km';              % file name prefix 
 
  % Grid Definition

  % Gridgen is designed to work with curvilinear and/or rectilinear grids. In
  % both cases it expects a 2D array defining the Longititudes (x values) and 
  % Lattitudes (y values). For curvilinear grids the user will have to use 
  % alternative software to determine these arrays. For rectilinear grids 
  % these are determined by the grid domain and desired resolution as shown 
  % below

  % NOTE : In gridgen we always define the longitudes in the 0 to 365 range as the 
  % boundary polygons have been defined in that range. It is fairly trivial to 
  % rearrange the grids to -180 to 180 range after they have been generated.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%inputs for polar stereographical grid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
earth_radius=6378137.0; %radius of ellipsoid, WGS84
eccentricity=0.08181919; %eccentricity, WGS84
north=1;%if south, north=0
resolution=40000; %km
lat_min=49; %the min abs(latitude) in the north/south hemisphere 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[lat,lon]=stereographic_lon_lat(lat_min,resolution,earth_radius,eccentricity,north);
%active_thickness=2.5*max(max(diff(lat))); 
active_thickness=1;
dx=min(max(abs(diff(lon))));
dy=min(max(abs(diff(lat))));

  ref_grid = 'etopo1';               % reference grid source 
                                     %      etopo1 = Etopo1 grid
                                     %      etopo2 = Etopo2 grid
  boundary = 'low';               % Option to determine which GSHHS 
                                     %  .mat file to load
                                     %         full = full resolution
                                     %         high = 0.2 km
                                     %         inter = 1 lm
                                     %         low   = 5 km
                                     %         coarse = 25 km 

% 0.c Setting the paths for subroutines

 addpath(bin_dir,'-end');

% 0.d Reading Input data

  read_boundary = 1;              % flag to determine if input boundary 
                                  % information needs to be read boundary 
                                  % data files can be significantly large 
                                  % and needs to be read only the first 
                                  % time. So when making multiple grids 
                                  % the flag can be set to 0 for subsequent 
                                  % grids. (Note : If the workspace is
                                  % cleared the boundary data will have to 
                                  % be read again)

  opt_poly = 0;                   % flag for reading the optional user 
                                  % defined polygons. Set to 0 if you do
                                  % not wish to use this option

  if (read_boundary == 1)

      fprintf(1,'.........Reading Boundaries..................\n');


      load([ref_dir,'/coastal_bound_',boundary,'.mat']); 

      N = length(bound);
      Nu = 0;
      if (opt_poly == 1)
          [bound_user,Nu] = optional_bound(ref_dir,fname_poly);       
      end                                             
      if (Nu == 0)
          opt_poly = 0;
      end

  end

% 0.d Parameter values used in the software

  DRY_VAL = 999999;               % Depth value for dry cells (can change as desired)
  MSL_LEV = 0.0;                  % Bathymetry level indicating wet / dry cells
                                  % all bathymetry values below this level are 
                                  % considered wet
  CUT_OFF = 0.1;                  % Proportion of base bathymetry cells that need to be 
                                  % wet for the target cell to be considered wet. 

  % NOTE : If you have accurate boundary polygons then it is better to have a low value for
  %        CUT_OFF which will make the target bathymetry cell wet even when there are only few
  %        wet cells in the base bathymetry. This will then be cleaned up by the polygons in 
  %        the mask cleanup section. If on the other hand you do not inttend to use the 
  %        polygons to define the coastal domains then you are better off using CUT_OFF = 0.5
 
  LIM_VAL = 0.5;                  % Fraction of cell that has to be inside a polygon for 
                                  % cell to be marked dry;
  OFFSET = max([dx dy]);          % Additional buffer around the boundary to check if cell 
                                  % is crossing boundary. Should be set to largest grid res. 

  LAKE_TOL = -1;                  % See documentation on remove_lake routine for possible 
                                  % values. 
  IS_GLOBAL = 0;                  % Set to 1 for global grids

  OBSTR_OFFSET = 1;               % See documentation for create_obstr for details
 
% 1. Generate the grid

  fprintf(1,'.........Creating Bathymetry..................\n');  

  depth = generate_grid(lon,lat,ref_dir,ref_grid,CUT_OFF,MSL_LEV,DRY_VAL);
         
% 2. Computing boundaries within the domain

  fprintf(1,'.........Computing Boundaries..................\n');

% 2.a Set the domain big enough to include the cells along the edges of the grid
  
  lon_start = min(min(lon))-dx;
  lon_end = max(max(lon))+dx;
  lat_start = min(min(lat))-dy;
  lat_end = max(max(lat))+dy;

% 2.b Extract the boundaries from the GSHHS and the optional databases
%     the subset of polygons within the grid domain are stored in b and b_opt
%     for GSHHS and user defined polygons respectively

  coord = [lat_start lon_start lat_end lon_end];
  [b,N1] = compute_boundary(coord,bound);
  if (opt_poly == 1)
      [b_opt,N2] = compute_boundary(coord,bound_user);     
  end

% 3. Set up Land - Sea Mask

% 3.a Set up initial land sea mask. The cells can either all be set to wet
%      or to make the code more efficient the cells marked as dry in 
%      'generate_grid' can be marked as dry cells

  m = ones(size(depth)); 
  m(depth == DRY_VAL) = 0; 

% 3.b Split the larger GSHHS polygons for efficient computation of the 
%     land sea mask. This is an optional step but recomended as it  
%     significantly speeds up the computational time. Rule of thumb is to
%     set the limit for splitting the polygons at least 4-5 times dx,dy

  fprintf(1,'.........Splitting Boundaries..................\n');

  b_split = split_boundary(b,5*max([dx dy]));

% 3.c Get a better estimate of the land sea mask using the polygon data sets.
%     (NOTE : This part will have to be commented out if cells above the 
%      MSL are being marked as wet, like in inundation studies)

  fprintf(1,'.........Cleaning Mask..................\n');
  
 % GSHHS Polygons. If 'split_boundary' routine is not used then replace
 % b_split with b  


  m2 = clean_mask(lon,lat,m,b_split,LIM_VAL,OFFSET);
  %m2 = clean_mask(lon,lat,m,b,LIM_VAL,OFFSET);
  
 % Masking out regions defined by optional polygons
 
  if (opt_poly == 1 && N2 ~= 0)
      m3 = clean_mask(lon,lat,m2,b_opt,LIM_VAL,OFFSET);       
  else                                              
      m3 = m2;
  end

% 3.d Remove lakes and other minor water bodies

  fprintf(1,'.........Separating Water Bodies..................\n');

  
  [m4,mask_map] = remove_lake(m3,LAKE_TOL,IS_GLOBAL); 
   m4(lat<lat_min)=3;
   [i1,j1]=find(m4==1);
   for i=1:length(i1)
       if lat(i1(i),j1(i))<lat_min+active_thickness
           m4(i1(i),j1(i))=2;
       end
   end
  

% 4. Generate sub - grid obstruction sets in x and y direction, based on 
%    the final land/sea mask and the coastal boundaries
    
  fprintf(1,'.........Creating Obstructions..................\n');

  [sx1,sy1] = create_obstr(lon,lat,b,m4,OBSTR_OFFSET,OBSTR_OFFSET);      
  
% 5. Output to ascii files for WAVEWATCH III

  depth_scale = 1000;
  obstr_scale = 100;

  d = round((depth)*depth_scale);
  write_ww3file([out_dir,'/',fname,'.depth_ascii'],d);                 

  write_ww3file([out_dir,'/',fname,'.maskorig_ascii'],m4);             

  d1 = round((sx1)*obstr_scale);
  d2 = round((sy1)*obstr_scale);
  write_ww3obstr([out_dir,'/',fname,'.obstr_lev1'],d1,d2);            

  write_ww3meta([out_dir,'/',fname],'RECT',lon,lat,1/depth_scale,...
                                  1/obstr_scale,1.0);          

% 6. Vizualization (this part can be commented out if resources are limited)


mymap = [0.2 0.1 0.5
    0.1 0.5 0.8
    0.2 0.7 0.6
    0.8 0.7 0.3];


width=1000;  % Width of figure for movie [pixels]
height=500;  % Height of figure of movie [pixels]
left=200;     % Left margin between figure and screen edge [pixels]
bottom=200;  % Bottom margin between figure and screen edge [pixels]


loc = find(m4 == 0);
d2 = depth;
%d2(loc) = NaN;

figure(1)
set(gcf,'Position', [left bottom width height])
axesm eckert4
geoshow(lat,lon,d2,'DisplayType','surface')
framem
gridm
colorbar
caxis([-4000 0])
title(['Bathymetry for ',fname],'fontsize',14);
set(gca,'fontsize',14);
clear d2;



figure(2);
set(gcf,'Position', [left bottom width height])
clf;
d2 = mask_map;
loc2 = find(mask_map == -1);
%d2(loc2) = NaN;
axesm eckert4
geoshow(lat,lon,d2,'DisplayType','surface')
framem
gridm
shading flat;
cbh=colorbar
colormap(mymap)
set(cbh,'XTick',[0:1:3])
set(cbh,'XTickLabel',[0:1:3])
caxis([-.5 3.5])
title(['Different water bodies for ',fname],'fontsize',14);
set(gca,'fontsize',14);
clear d2;
   



figure(3);
set(gcf,'Position', [left bottom width height])
clf;
axesm eckert4
geoshow(lat,lon,m4,'DisplayType','surface')
framem
gridm
shading flat;
cbh=colorbar
colormap(mymap)
set(cbh,'XTick',[0:1:3])
set(cbh,'XTickLabel',[0:1:3])
caxis([-.5 3.5])
title(['Final Land-Sea Mask ',fname],'fontsize',14);
set(gca,'fontsize',14);


  

figure(4);
set(gcf,'Position', [left bottom width height])
clf;
d2 = sx1;
%d2(loc) = NaN;
axesm eckert4
geoshow(lat,lon,d2,'DisplayType','surface')
framem
gridm
shading flat;
colorbar;
title(['Sx obstruction for ',fname],'fontsize',14);
set(gca,'fontsize',14);
clear d2;



figure(5);
set(gcf,'Position', [left bottom width height])
clf;
d2 = sy1;
%d2(loc) = NaN;
axesm eckert4
geoshow(lat,lon,d2,'DisplayType','surface')
framem
gridm
shading flat;
colorbar;
title(['Sy obstruction for ',fname],'fontsize',14);
set(gca,'fontsize',14);
clear d2;

% END OF SCRIPT


