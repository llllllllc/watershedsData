setwd("./")
library(foreign)

result<-read.dbf("output/sub.dbf")#運算成果
testdata<-read.csv("test/testdata.csv")#測試資料
testing<-as.matrix(sapply(result[,c(3:7)], as.numeric))-as.matrix( sapply(testdata[,c(3:7)], as.numeric))
testing1<- round(testing[,c(1,3,4,5)], 3)
testing<- cbind(round(testing[,c(2)], 0),testing1)
if(sum(testing>0)==0){
  cat("Passed the test")
}else{
  cat("fail")
}
