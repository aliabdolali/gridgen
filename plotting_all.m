clear all
clc
%aoc

earth_radius=6378137.0; %radius of ellipsoid, WGS84
eccentricity=0.08181919; %eccentricity, WGS84
north=1;%if south, north=0
resolution=40000; %km
lat_min=49; %the min abs(latitude) in the north/south hemisphere 

[LATAOC,LONAOC]=stereographic_lon_lat(lat_min,resolution,earth_radius,eccentricity,north);

DEPTHAOC=load('OUTPUT-PATH/ArcticStereographic40km.depth_ascii')/1000;
MASKAOC=load('OUTPUT-PATH/ArcticStereographic40km.maskorig_ascii');
OBSAOC=load('OUTPUT-PATH/ArcticStereographic40km.obstr_lev1');


 %gnh
LONGNH(:,1)=0:1/2:360-1/2;
LATGNH(:,1)=-15:1/2:52.5;
[LONNGNH,LATNGNH]=meshgrid(LONGNH,LATGNH);
DEPTHGNH=(load('OUTPUT-PATH_GNH/gnh_30m.depth_ascii'))/1000;
MASKGNH=load('OUTPUT-PATH_GNH/gnh_30m.maskorig_ascii');
OBSGNH=load('OUTPUT-PATH_GNH/gnh_30m.obstr_lev1');

 %gsh
LONGSH(:,1)=0:1:360-1/4;
LATGSH(:,1)=-79.5000:1:-10.5;
[LONNGSH,LATNGSH]=meshgrid(LONGSH,LATGSH);
DEPTHGSH=(load('OUTPUT-PATH_GSH/gsh_1deg.depth_ascii'))/1000;
MASKGSH=load('OUTPUT-PATH_GSH/gsh_1deg.maskorig_ascii');
OBSGSH=load('OUTPUT-PATH_GSH/gsh_1deg.obstr_lev1');

%%
close all

mymap = [0.2 0.1 0.5
    0.1 0.5 0.8
    0.2 0.7 0.6
    0.8 0.7 0.3];


width=1000;  % Width of figure for movie [pixels]
height=500;  % Height of figure of movie [pixels]
left=200;     % Left margin between figure and screen edge [pixels]
bottom=200;  % Bottom margin between figure and screen edge [pixels]

new_origin=[0,0]; %for changing the origin of plot (the default is [0 0] 
%[LATN,LONN]=rotatem(LAT,LON,new_origin,'inverse','degrees');

load coast
  figure
set(gcf,'Position', [left bottom width height])
axesm eckert4
%%% if you want the plot on a sphere
%setm(gca,'mapprojection','ortho') 
geoshow(LATAOC,LONAOC,DEPTHAOC,'DisplayType','surface')
hold on
geoshow(LATNGSH,LONNGSH,DEPTHGSH,'DisplayType','surface')
hold on
geoshow(LATNGNH,LONNGNH,DEPTHGNH,'DisplayType','surface')
hold on
plotm(lat,long,'k')

framem
gridm
colorbar
caxis([-4000 0])
title('depth [m]')

print(gcf,'-dpng',['depth.png'],'-r500');

 

  figure
set(gcf,'Position', [left bottom width height])
axesm eckert4
%%% if you want the plot on a sphere
%setm(gca,'mapprojection','ortho') 
geoshow(LATAOC,LONAOC,MASKAOC,'DisplayType','surface')
hold on
geoshow(LATNGSH,LONNGSH,MASKGSH,'DisplayType','surface')
hold on
geoshow(LATNGNH,LONNGNH,MASKGNH,'DisplayType','surface')
hold on
plotm(lat,long,'k')
framem
gridm
cbh=colorbar
colormap(mymap)
set(cbh,'XTick',[0:1:3])

%set(cbh,'XTickLabel',{'0','1','2','3'})
caxis([-.5 3.5])
title('MASK')
print(gcf,'-dpng',['MASK.png'],'-r500');


  figure
set(gcf,'Position', [left bottom width height])
axesm eckert4
%%% if you want the plot on a sphere
%setm(gca,'mapprojection','ortho') 
geoshow(LATAOC,LONAOC,OBSAOC(1:length(LATAOC(:,1)),:),'DisplayType','surface')
hold on
geoshow(LATNGSH,LONNGSH,OBSGSH(1:length(LATGSH(:,1)),:),'DisplayType','surface')
hold on
geoshow(LATNGNH,LONNGNH,OBSGNH(1:length(LATGNH(:,1)),:),'DisplayType','surface')
hold on
plotm(lat,long,'k')
framem
gridm
colorbar
caxis([0 100])
title('OBS_x')
print(gcf,'-dpng',['OBS1.png'],'-r500');
  figure
set(gcf,'Position', [left bottom width height])
axesm eckert4
%%% if you want the plot on a sphere
%setm(gca,'mapprojection','ortho') 
geoshow(LATAOC,LONAOC,OBSAOC(length(LATAOC(:,1))+1:end,:),'DisplayType','surface')
hold on
geoshow(LATNGSH,LONNGSH,OBSGSH(length(LATGSH(:,1))+1:end,:),'DisplayType','surface')
hold on
geoshow(LATNGNH,LONNGNH,OBSGNH(length(LATGNH(:,1))+1:end,:),'DisplayType','surface')
hold on
plotm(lat,long,'k')
framem
gridm
colorbar
caxis([0 100])
title('OBS_y')
print(gcf,'-dpng',['OBS2.png'],'-r500');
