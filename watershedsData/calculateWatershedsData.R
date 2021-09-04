#START OF載入packages###########################
setwd("./")#定位至.R檔案所在位置
if(!require(sp)){
  install.packages("sp",repos = "http://cran.us.r-project.org")
}
if(!require(raster)){
  install.packages("raster",repos = "http://cran.us.r-project.org")
}
if(!require(rgdal)){
  install.packages("rgdal",repos = "http://cran.us.r-project.org")
}
if(!require(rgeos)){
  install.packages("rgeos",repos = "http://cran.us.r-project.org")
}
if(!require(maptools)){
  install.packages("maptools",repos = "http://cran.us.r-project.org")
}
if(!require(foreign)){
  install.packages("foreign",repos = "http://cran.us.r-project.org")
}
if(!require(dplyr)){
  install.packages("dplyr",repos = "http://cran.us.r-project.org")
}
if(!require(shotGroups)){
  install.packages("shotGroups",repos = "http://cran.us.r-project.org")
}
library(sp)
library(raster)
library(rgdal)
library(rgeos)
library(maptools)
library(foreign)
library(dplyr)
library(shotGroups)
#END OF載入packages###########################


#STAR OF檔案清除###########################
# if exist  output folder --> delete
# else --> do nothing
# create folder

if(file.exists("output")){
  unlink("output", recursive = TRUE)
}
dir.create("output")
if(file.exists("work")){
  unlink("work", recursive = TRUE)
}
dir.create("work")
#END OF檔案清除###########################


#START OF複製input到WORK資料夾###########################
#複製土地利用圖
landuse<-as(shapefile("input/landuse.shp",use_iconv=TRUE, encoding = "UTF-8"),'SpatialPolygonsDataFrame')#library(raster)
lData<-landuse@data["SCS_NO"]#擷取SCS_NO，清除雜項
landuse@data<-lData#存入SCS_NO，替換掉原有的
writeOGR(landuse, ".", dsn="work/landuse.shp", driver="ESRI Shapefile")
#複製集水區分區圖
sub<-as(shapefile("input/sub.shp",use_iconv=TRUE, encoding = "UTF-8"),'SpatialPolygonsDataFrame')#library(raster)
sData<-sub@data[c("NAME","out")]#擷取NAME、out，清除雜項
sub@data<-sData#存入NAME、out，替換掉原有的
writeOGR(sub, ".", dsn="work/sub.shp", driver="ESRI Shapefile")
#複製DTM檔(RASTER)



if(file.exists("input/raster")){
  DTM<-raster("input/raster",use_iconv=TRUE, encoding = "UTF-8")
  writeRaster(DTM, 'work/DTM.tif', overwrite=TRUE)
}
#複製SCS與要加權平均的值的對照表
SCSValue<-read.table("input/SCS_CN_and_IMP.csv",header=T,sep=",")
write.csv(SCSValue,"work/SCS_CN_and_IMP.csv",row.names = F)
#清除
rm(list = ls())
print("檔案複製至work")
#END OF複製input到WORK資料夾###########################


#START OF計算sub的Area(ha)###########################
sub<- as(shapefile("work/sub.shp",use_iconv=TRUE, encoding = "UTF-8"),'SpatialPolygonsDataFrame')
area=as.numeric(area(sub)/10000)#計算面積(m2)，再將單位由m2轉換成ha
dbfdata <- sub@data
dbfdataAdd<-matrix(NA,nrow(dbfdata),1)
colnames(dbfdataAdd)<-c("Area")
dbfdataAdd[,1]<-area
dbfdata=cbind(dbfdata,dbfdataAdd)
write.dbf(dbfdata, "work/sub.dbf")
print("計算sub的Area(m2)")
read.dbf("work/sub.dbf")[,c("NAME","Area")]
rm(list = ls())#清除
#END OF計算sub的Area(ha)###########################


#START OF計算各個集水區平均slope(%)###########################
#以terrain(raster package)計算網格坡度slope(PERCENT RISE)(%)
if(file.exists("work/DTM.tif")){
  DTM<-raster("work/DTM.tif",use_iconv=TRUE, encoding = "UTF-8")#library(raster)
  #有DTM檔案才計算slope
  slope<-terrain(DTM,opt="slope",units="radians")#計算網格坡度
  fun <- function(x) { tan(x)*100 }#單位轉換，將radians轉換為PERCENT RISE(%)
  slope<-calc(slope, fun)#單位轉換，將radians轉換為PERCENT RISE(%)
  writeRaster(slope, 'output/slope.tif', overwrite=TRUE)#輸出坡度slope網格
  #以extract(raster package)計算各個集水區平均坡度slope(%) 
  sub<- as(shapefile("work/sub.shp",use_iconv=TRUE, encoding = "UTF-8"),'SpatialPolygonsDataFrame')
  sub<- extract(slope, sub, fun=mean, na.rm=TRUE, sp = T)#計算各個集水區平均坡度slope(PERCENT RISE)(%) 
  names(sub@data)[names(sub@data) == "layer"] <- "slope"#將計算出來的結果的欄位名稱換成slope
  write.dbf(sub@data, "work/sub.dbf")#重寫集水區dbf
  #writeOGR(sub, ".", dsn="work/sub.shp", driver="ESRI Shapefile")#重寫集水區shp
}
#清除
rm(list = ls())
print("計算集水區平均SLOPE")
#END OF計算各個集水區平均slope(%)########################### 


#START OF 計算集水區特徵寬度(以最小寬度箱型法近似)###########################
source("GetMinWidthBBox.R")#載入function
sub<- as(shapefile("work/sub.shp",use_iconv=TRUE, encoding = "UTF-8"),'SpatialPolygonsDataFrame')
w<-matrix(NA,nrow(sub@data),1)
colnames(w)<-c("W")
for (i in c(1:nrow(sub@data))) {
  xy<-sub@polygons[[i]]@Polygons[[1]]@coords
  bb <- getMinWidthBBox(xy)#以最小寬度的長方形
  w[i]<-bb$minWidth/2#其實不太懂
}
w<-as.data.frame(w)
dbfdata=cbind(sub@data,w)
write.dbf(dbfdata, "work/sub.dbf")
#清除
rm(list = ls())
print("計算集水區特徵寬度")
#END OF 計算集水區特徵寬度(以最小寬度箱型法近似)###########################


#START OF在landuse中加入要平均的值###########################
SCS<-read.csv("work/SCS_CN_and_IMP.csv")#要以landuse加權平均的值
landuse<-shapefile("work/landuse.shp",use_iconv=TRUE, encoding = "UTF-8")#library(raster)
for (i in c(2:ncol(SCS))) {#看有幾種要加入平均的值
  calName<-colnames(SCS)[i]
  dbfdata <- landuse@data
  dbfdataAdd<-matrix(NA,nrow(dbfdata),1)
  colnames(dbfdataAdd)<-c(calName)
  joindata<-SCS[,c(1,i)]
  for (j in 1:nrow(joindata)) {
    dbfdataAdd[which(dbfdata[,'SCS_NO']==joindata[j,1]),1]=joindata[j,2]#以SCS_NO對應來加入值
  }
  dbfdata=cbind(dbfdata,dbfdataAdd)#將原本的data跟要加入的合併
  landuse@data<-dbfdata#將原本的data跟要加入的合併
}
write.dbf(dbfdata, "work/landuse.dbf")#library(foreign)
rm(list = ls())
print("在landuse中加入要加權平均的值")
#END OF 在landuse中加入要平均的值###########################

#START OF intersect subwatersheds&landuse###########################
landuse<-as(shapefile("work/landuse.shp",use_iconv=TRUE, encoding = "UTF-8"),'SpatialPolygonsDataFrame')#library(raster)
sub<- as(shapefile("work/sub.shp",use_iconv=TRUE, encoding = "UTF-8"),'SpatialPolygonsDataFrame')
sub_inter <- raster::intersect(sub, landuse)#集水區與土地利用圖intersect
sub_inter<-as(sub_inter,'SpatialPolygonsDataFrame')
writeOGR(sub_inter, ".", dsn="work/sub_inter.shp", driver="ESRI Shapefile")
png("output/intersect.jpg", width = 9, height =12, units = 'in', res = 400)#畫圖
plot(landuse, axes=T); plot(sub, add=T); plot(sub_inter, add=T, col='red')
dev.off()
rm(list = ls())
print("intersect subwatersheds&landuse")
#END OF intersect subwatersheds&landuse###########################

#START OF計算sub_inter的Area(ha)###########################
sub_inter<- as(shapefile("work/sub_inter.shp",use_iconv=TRUE, encoding = "UTF-8"),'SpatialPolygonsDataFrame')
area=as.numeric(area(sub_inter)/10000)#計算面積(m2)，再將單位由m2轉換成ha
dbfdata <- sub_inter@data
dbfdataAdd<-matrix(NA,nrow(dbfdata),1)
colnames(dbfdataAdd)<-c("area_int")
dbfdataAdd[,1]<-area
dbfdata=cbind(dbfdata,dbfdataAdd)
write.dbf(dbfdata, "work/sub_inter.dbf")#library(foreign)
print("計算intersect結果的Area(ha)")
rm(list = ls())
#END OF計算sub_inter的Area(ha)###########################


#START OF計算加權值###########################
SCS<-read.csv("work/SCS_CN_and_IMP.csv")#集水區內要以landuse加權平均的值
sub_inter<- as(shapefile("work/sub_inter.shp",use_iconv=TRUE, encoding = "UTF-8"),'SpatialPolygonsDataFrame')
sub<- as(shapefile("work/sub.shp",use_iconv=TRUE, encoding = "UTF-8"),'SpatialPolygonsDataFrame')
subData<-sub@data
for (i in c(2:ncol(SCS))) {
  calName<-colnames(SCS)[i]
  sub_interData <- sub_inter@data
  valueInt<-sub_interData[,calName]*sub_interData[,"area_int"]/sub_interData[,"Area"]#加權
  valueSub<-matrix(NA,nrow(subData),1)
  for (j in 1:length(valueSub)) {
    valueSub[j]<-sum(valueInt[which(sub_interData[,"NAME"]==subData[j,"NAME"])])#依集水區名稱加總
  }
  colnames(valueSub)<-c(calName)
  subData=cbind(subData,valueSub)
}
write.dbf(subData, "work/sub.dbf")#library(foreign)
rm(list = ls())
#END OF計算加權CN值###########################


#START OF集水區參數計算結果複製到output###########################
sub<-as(shapefile("work/sub.shp",use_iconv=TRUE, encoding = "UTF-8"),'SpatialPolygonsDataFrame')#library(raster)
writeOGR(sub, ".", dsn="output/sub.shp", driver="ESRI Shapefile")
rm(list = ls())
#END OF集水區參數計算結果複製到output###########################
cat("...\n\n")
cat(".....\n")
print("calculation complete")
cat("\n")

