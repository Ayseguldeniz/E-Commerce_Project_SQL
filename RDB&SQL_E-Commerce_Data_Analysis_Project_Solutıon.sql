
--RDB&SQL E-Commerce Data Analysis Project

--call the tables..
select *
from shipping_dimen

SELECT *
FROM prod_dimen

SELECT*
FROM cust_dimen

SELECT*
FROM orders_dimen

select*
from market_fact$


UPDATE orders_dimen
SET Ord_ID =TRIM('Ord_' FROM Ord_ID)

UPDATE prod_dimen
SET Prod_ID =TRIM('Prod_' FROM Prod_ID)

UPDATE cust_dimen
SET Cust_ID =TRIM('Cust_' FROM Cust_ID)
 
UPDATE shipping_dimen
SET Ship_ID =TRIM('SHP_' FROM Ship_ID)

UPDATE market_fact
SET Ord_ID =TRIM('Ord_' FROM Ord_ID)

UPDATE market_fact
SET Cust_ID =TRIM('Cust_' FROM Cust_ID)

UPDATE market_fact
SET Prod_ID =TRIM('Prod_' FROM Prod_ID)

UPDATE market_fact
SET Ship_ID =TRIM('SHP_' FROM Ship_ID)


--nvarchar olan s�tunlar� integer a cevirdik.
ALTER TABLE Shipping_Dimen ALTER COLUMN Ship_ID INT;
ALTER TABLE cust_dimen ALTER COLUMN Cust_ID INT;
ALTER TABLE prod_dimen ALTER COLUMN Prod_ID INT;
ALTER TABLE orders_dimen ALTER column Ord_ID INT;
ALTER TABLE market_fact ALTER COLUMN Ord_ID INT;

--1)Using the columns of �market_fact�, �cust_dimen�, �orders_dimen�, �prod_dimen�, �shipping_dimen�, Create a new table, named as �combined_table�.
--1)�market_fact�, �cust_dimen�, �orders_dimen�, �prod_dimen�, �shipping_dimen� s�tunlar�n� kullanarak �combined_table� ad�nda yeni bir tablo olu�turun.

SELECT B.*, C.*, D.*, E.*, A.Sales, A.Discount, A.Order_Quantity, A.Product_Base_Margin
INTO combined_table
FROM dbo.market_fact A,
dbo.cust_dimen B,
dbo.orders_dimen C,
dbo.prod_dimen D,
dbo.shipping_dimen E
WHERE A.Cust_ID = B.Cust_ID
AND A.Ord_ID = C.Ord_ID
AND A.Prod_ID = D.Prod_ID
AND A.Ship_ID = E.Ship_ID


--2. Find the top 3 customers who have the maximum count of orders.
--2. Maksimum sipari� say�s�na sahip ilk 3 m��teriyi bulun.

WITH T1 AS
(
SELECT DISTINCT Cust_ID , Customer_Name,COUNT( Ord_ID) OVER(PARTITION BY Cust_ID,Customer_Name ) AS CNT_ORDER 
FROM combined_table
)
SELECT TOP(3) Cust_ID, Customer_Name, CNT_ORDER
FROM T1
ORDER BY 3 DESC

--OTHER WAY

SELECT TOP(3) Cust_ID , Customer_Name,COUNT( Order_Quantity)  AS CNT_ORDER 
FROM combined_table
GROUP BY Cust_ID, Customer_Name
ORDER BY CNT_ORDER DESC


--3. Create a new column at combined_table as DaysTakenForShipping that contains the date difference of Order_Date and Ship_Date.
--3. Combine_table'da, Order_Date ve Ship_Date aras�ndaki tarih fark�n� i�eren DaysTakenForShipping olarak yeni bir s�tun olu�turun.

-- create a new table
ALTER TABLE combined_table
ADD DaysTakenForShipping INT 

-- fill in table
UPDATE combined_table
SET DaysTakenForShipping =DATEDIFF(DAY,Order_Date,Ship_Date)

--control it
SELECT*
FROM combined_table

--4. Find the customer whose order took the maximum time to get shipping.
--4. Sipari�inin kargoya verilmesi i�in maksimum s�reyi alan m��teriyi bulun.


SELECT TOP(1) DaysTakenForShipping, Cust_ID,Customer_Name
FROM combined_table                   
ORDER BY DaysTakenForShipping DESC



--5. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
--5. Ocak ay�ndaki toplam benzersiz m��teri say�s�n� ve 2011'de t�m y�l boyunca ka� tanesinin her ay geri geldi�ini say�n.


-------unique m��teri say�s�
--SELECT COUNT(DISTINCT Cust_ID) 
--FROM combined_table


-- Count the total number of  customers in January 
SELECT  DISTINCT  YEAR(Order_Date) ord_year,MONTH(Order_Date) ord_month,
count(Cust_ID ) OVER (PARTITION BY YEAR(Order_Date)) AS COUNT_CUST
FROM combined_table
WHERE MONTH(Order_Date)= 1
ORDER BY 2,1



--Customers in January 2011
SELECT DISTINCT Cust_ID 
FROM combined_table
WHERE MONTH(Order_Date)= 1
AND YEAR(Order_Date) =2011

--how many of them came back every month over the entire year in 2011
SELECT count(DISTINCT Cust_ID ) cnt_cust, MONTH(Order_Date) ord_month
FROM combined_table
WHERE Cust_ID IN
    (
	SELECT DISTINCT Cust_ID 
	FROM combined_table
	WHERE MONTH(Order_Date)= 1
	AND YEAR(Order_Date) =2011
    )
AND YEAR(Order_Date) =2011
GROUP BY  MONTH(Order_Date)

--P�VOT �LE DENE AYNI SORUYU

--6. Write a query to return for each user the time elapsed between the first purchasing and the third purchasing, in ascending order by Customer ID.
--6. Her kullan�c� i�in ilk sat�n alma ile ���nc� sat�n alma aras�nda ge�en s�reyi M��teri Kimli�ine g�re artan s�rada d�nd�recek bir sorgu yaz�n.

--Here,min represents the first order, while the value of 3 for dense_rank represents the 3rd order
SELECT DISTINCT Cust_ID, Order_Date, 
       MIN(Order_Date )   OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS first_order,
       DENSE_RANK() OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS thrd_order
FROM combined_table

--Now let's choose from this table we have obtained..

WITH T1 AS
(
SELECT Cust_ID, Order_Date, 
       MIN(Order_Date )   OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS first_order,
       DENSE_RANK() OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS thrd_order
FROM combined_table
)

SELECT DISTINCT Cust_ID,Order_Date, 
       DATEDIFF(DAY,first_order,Order_Date) AS PREV_PASS_TIME
FROM T1
WHERE thrd_order =3



--7. Write a query that returns customers who purchased both product 11 and product 14, as well as the ratio of these products to the total number of products purchased by the customer.
--7. Hem 11. �r�n� hem de 14. �r�n� sat�n alan m��terileri ve bu �r�nlerin m��teri taraf�ndan sat�n al�nan toplam �r�n say�s�na oran�n� veren bir sorgu yaz�n.
---- returns customers who purchased both product 11 and product 14..
--SELECT DISTINCT Cust_ID
--FROM  combined_table
--WHERE Prod_ID = 11 
--INTERSECT
--SELECT DISTINCT Cust_ID 
--FROM  combined_table
--WHERE Prod_ID = 14


WITH T1 AS
(
SELECT Cust_ID,COUNT(Prod_ID) AS TOTAL_PROD_11_14,
       SUM(CASE WHEN Prod_ID=11 THEN 1 ELSE 0 END)AS CNT_PROD_11,
       SUM(CASE WHEN Prod_ID=14 THEN 1 ELSE 0 END)AS CNT_PROD_14
FROM combined_table
WHERE Cust_ID IN
	(SELECT DISTINCT Cust_ID
	FROM  combined_table
	WHERE Prod_ID = 11 
	INTERSECT
	SELECT DISTINCT Cust_ID 
	FROM  combined_table
	WHERE Prod_ID = 14)
GROUP BY Cust_ID
)

SELECT Cust_ID, ROUND(CAST(CNT_PROD_11 AS  FLOAT )/CAST(TOTAL_PROD_11_14 AS FLOAT),2) AS RATIO_OF_11,
                ROUND(CAST(CNT_PROD_14 AS  FLOAT )/CAST(TOTAL_PROD_11_14 AS FLOAT),2)AS RATIO_OF_14
FROM T1



--Customer Segmentation
--M��teri segmentasyonu
--Categorize customers based on their frequency of visits. The following steps will guide you. If you want, you can track your own way.
--M��terileri ziyaret s�kl���na g�re kategorilere ay�r�n. A�a��daki ad�mlar size rehberlik edecektir. Dilerseniz kendi yolunuzu takip edebilirsiniz.


--1. Create a �view� that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)
--1. M��terilerin ziyaret g�nl�klerini ayl�k olarak tutan bir "g�r�n�m" olu�turun. (Her log i�in �� alan tutulur: Cust_id, Year, Month)

CREATE OR ALTER VIEW [dbo].[visit_log_cust] AS
SELECT  DISTINCT Cust_ID,YEAR(Order_Date) AS ord_year, MONTH(Order_Date) AS ord_month
FROM combined_table


 --control a new wiew
 SELECT *
 FROM visit_log_cust
 ORDER BY 1,2,3



--2. Create a �view� that keeps the number of monthly visits by users. (Show separately all months from the beginning business)
--2. Kullan�c�lar�n ayl�k ziyaretlerinin say�s�n� tutan bir "g�r�n�m" olu�turun. (�� ba�lang�c�ndan itibaren t�m aylar� ayr� ayr� g�sterin)

CREATE OR ALTER VIEW [dbo].[num_of_montly_visits] AS
SELECT DISTINCT Cust_ID,Order_Date,Order_ID,
       YEAR(Order_Date) AS ord_year, 
	   MONTH(Order_Date) AS ord_month,
       COUNT(Cust_ID) OVER (PARTITION BY Cust_ID, Order_Date ORDER BY Order_Date,YEAR(Order_Date),MONTH(Order_Date)) AS num_of_order
FROM combined_table

SELECT *
FROM num_of_montly_visits


--3. For each visit of customers, create the next month of the visit as a separate column.
--3. M��terilerin her ziyareti i�in, ziyaretin bir sonraki ay�n� ayr� bir s�tun olarak olu�turun.

CREATE OR ALTER VIEW [dbo].[next_visit] AS
SELECT Cust_ID, ord_year,ord_month,Order_Date,
     LEAD( Order_Date)  OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS next_order,
     YEAR(LEAD( Order_Date)  OVER (PARTITION BY Cust_ID ORDER BY Order_Date)) AS next_order_year,
     MONTH(LEAD(Order_Date) OVER (PARTITION BY Cust_ID ORDER BY Order_Date) )AS next_order_month
FROM num_of_montly_visits


SELECT*
FROM next_visit



--4. Calculate the monthly time gap between two consecutive visits by each customer.
--4. Her m��terinin birbirini takip eden iki ziyareti aras�ndaki ayl�k zaman aral���n� hesaplay�n.
CREATE OR ALTER VIEW [dbo].[montly_t�me_gap] AS
SELECT *,
     DATEDIFF(month, Order_Date,next_order) as gap
FROM next_visit

select*
from montly_t�me_gap


--5. Categorise customers using average time gaps. Choose the most fitted labeling model for you.
--5. Ortalama zaman bo�luklar�n� kullanarak m��terileri kategorilere ay�r�n. Size en uygun etiketleme modelini se�in.

WITH T1 AS 
(
SELECT DISTINCT Cust_ID, 
       AVG(gap)  OVER (PARTITION BY Cust_ID) AS avg_gap
FROM montly_t�me_gap

)
SELECT DISTINCT Cust_ID,
case 
 when avg_gap IS NULL then 'lost '
 when avg_gap >=25 then 'lagger' 
 when avg_gap <25 and avg_gap >=10 then 'little_lagger'
 when avg_gap < 10  then 'retained' end as case_of_retained
FROM T1
order by 1



--Month-Wise Retention Rate
--Find month-by-month customer retention ratei since the start of the business.
--There are many different variations in the calculation of Retention Rate. But we will
--try to calculate the month-wise retention rate in this project.
--So, we will be interested in how many of the customers in the previous month could
--be retained in the next month.
--Proceed step by step by creating �views�. You can use the view you got at the end of
--the Customer Segmentation section as a source.


--1. Find the number of customers retained month-wise. (You can use time gaps)
SELECT DISTINCT  ord_year,
       ord_month,
       COUNT (Cust_ID) OVER (PARTITION BY ord_year,ord_month)as retained_month_wise
FROM montly_t�me_gap
WHERE gap= 1
order by 1,2

--2. Calculate the month-wise retention rate.

WITH T1 AS
(SELECT DISTINCT  ord_year,
       ord_month,
       COUNT (Cust_ID) OVER (PARTITION BY ord_year,ord_month)as retained_month_wise
FROM montly_t�me_gap
WHERE gap= 1) , T2 AS
(SELECT DISTINCT  ord_year,
       ord_month,
       COUNT (Cust_ID) OVER (PARTITION BY ord_year,ord_month)as total_cust
FROM montly_t�me_gap)
SELECT DISTINCT*,(retained_month_wise*1.0)/(total_cust*1.0) AS month_wise_retention_rate
FROM T1,T2



















