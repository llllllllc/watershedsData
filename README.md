# watershedsData 1.0



## 功能簡介
#### 分析複數集水區的面積、平均坡度、特徵寬度、平均CN值、平均IMP值
輸入集水區與土地使用分區的 GIS 檔案，以及相對應的參數表等，可自動計算多個集水區的面積、坡度、特徵寬度、CN 值等數據。


#### 以shapefile形式輸出成果

計算成果儲存於.dbf檔案中，便於進行其餘分析(如匯入SWMM當中進行模擬)



## 使用方法

安裝方式:

1. 安裝R4.0
2. 在電腦環境變數中path新增R的路徑
3. 將"watershedsData 1.0"資料夾下載至桌面(資料夾中包含輸入參數範例)

使用方式:

1. 準備土地利用分類地圖並命名為landuse的shp檔，他的dbf表格中要有一欄SCS_NO(SCS代碼)
2. 準備一個SCS_CN_and_IMP.csv檔案，裡面需要有一欄對應NO(也就是landuse.shp中的SCS_NO)，其餘為你需要加權平均的數值(e.g.  CN、IMP)
3. 準備一個子集水分區並命名為sub的shp檔，dbf表格中要有一欄NAME(集水區名稱)
   ，跟一欄out(降雨逕流流入節點名稱，可作為匯入SWMM使用，若非用在SWMM則可以隨意設置)
4. 準備一個名為raster的網格檔案，內容為DTM的高程(如果沒有要算slope就不用放這個，程式會自動忽略slope的計算)
5. 將準備好的檔案放入input資料夾當中，程式運行過程不會改動到input資料夾內的檔案，有需要可以再到裡面修改
6. 開啟"watershedsData主程式.xlsm"點選run按鈕執行程式，結果會出現在output當中
7. 跳出運算視窗，等運算停止後按enter鍵結束運算(同時檢視運算過程，若計算完成會看到"calculation  complete")
8. 如果因為無法安裝R  packages而無法執行，先手動執行installPackage.R
9. 輸入檔案的格式可參考input資料夾中的檔案

## 成果檢視

輸出成果為output資料夾中名為sub的shapefile檔，包含以下數種數據：

1. Area：集水區的面積(ha)
2. slope：平均坡度(PERCENT RISE)(%)
3. W：特徵寬度(m)，採用近似方式求得次集水區之特徵寬度，可匯入swmm中進行集水區水文計算
4. CN(或者是使用者另外想要平均的數值)：平均CN值
5. IMP(或者是使用者另外想要平均的數值)：平均IMP值
6. output資料夾中intersect.jpg為集水區運算成果示意圖，可作為初步判斷運算成果

<img src=".\sub.png" alt="sub" style="zoom: 50%;" />
