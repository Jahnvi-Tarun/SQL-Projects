---Inspecting Data---

SELECT *
FROM [dbo].[sales_data_sample]

---Checking Unique Values---

SELECT DISTINCT STATUS from [dbo].[sales_data_sample]
SELECT DISTINCT YEAR_ID from [dbo].[sales_data_sample]
SELECT DISTINCT PRODUCTLINE from [dbo].[sales_data_sample]
SELECT DISTINCT COUNTRY FROM [dbo].[sales_data_sample]
SELECT DISTINCT DEALSIZE from [dbo].[sales_data_sample]
SELECT DISTINCT TERRITORY from [dbo].[sales_data_sample]

---ANALYSIS---
--Analyzing Sales by grouping productline---
SELECT PRODUCTLINE, SUM(SALES) AS Revenue
FROM [dbo].[sales_data_sample]
GROUP BY PRODUCTLINE
ORDER BY 2 desc

--Analyzing Sales by Year
SELECT YEAR_ID, SUM(SALES) AS Revenue
FROM [dbo].[sales_data_sample]
GROUP BY YEAR_ID
ORDER BY 2 desc

SELECT DISTINCT MONTH_ID FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2005
ORDER BY MONTH_ID

---Analyzing Sales by DealSize
SELECT DEALSIZE, SUM(SALES) AS Revenue
FROM [dbo].[sales_data_sample]
GROUP BY DEALSIZE
ORDER BY 2 desc

---What was the best month for sales in a particular year? How much was earned per month?
SELECT MONTH_ID , SUM(SALES) AS Revenue , COUNT(ORDERNUMBER) AS Frequency
FROM[dbo].[sales_data_sample]
WHERE YEAR_ID = 2004 ---change the year accordingly
GROUP BY MONTH_ID
ORDER BY 2 DESC

-- November seems to be the best month for sales in the year 2003, 2004. Which product generates the most sales?
SELECT MONTH_ID, PRODUCTLINE, SUM(SALES) AS Revenue ,  COUNT(ORDERNUMBER) AS Frequency
FROM[dbo].[sales_data_sample]
WHERE YEAR_ID = 2004 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC

---Who is our best customer? (RFM Analysis)
DROP TABLE IF EXISTS #rfm
;With rfm as (SELECT CUSTOMERNAME, 
        SUM(SALES) monetary_value, 
		AVG(SALES) Avg_monetary_value , 
		MAX(ORDERDATE) last_order_date , 
		COUNT(ORDERNUMBER) frequency, 
		(select max(ORDERDATE) FROM [dbo].[sales_data_sample]) max_order_date,
		DATEDIFF (DAY, MAX(ORDERDATE), (select max(ORDERDATE) FROM [dbo].[sales_data_sample])) Recency

FROM [dbo].[sales_data_sample]
GROUP BY CUSTOMERNAME
), 
rfm_calc as (
 
 SELECT r.*, 
  NTILE(4) OVER (Order by Recency desc) rfm_recency,
  NTILE(4) OVER ( Order by frequency) rfm_frequency,
  NTILE(4) OVER ( Order by monetary_value) rfm_monetaryvalue
 FROM rfm r
)

SELECT c.*,rfm_recency+rfm_frequency+rfm_monetaryvalue as rfm_cell,
CAST(rfm_recency as varchar) + CAST(rfm_frequency as varchar) + CAST(rfm_monetaryvalue as varchar) as rfm_cell_string
INTO #rfm
FROM rfm_calc c

SELECT CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetaryvalue,
	CASE 
		WHEN rfm_cell_string in ( 111, 112, 121, 122, 123, 132, 211, 212, 114, 141,221) THEN 'Lost customers' -- lost customers
		WHEN rfm_cell_string in ( 133, 134, 143, 244, 334, 343, 344) THEN 'Slipping away, cannot lose'
		WHEN rfm_cell_string in ( 232, 311, 411, 412, 331) THEN 'New Customers'
		WHEN rfm_cell_string in ( 222, 223, 233, 322, 421) THEN 'Potential Churners'
		WHEN rfm_cell_string in ( 144, 234, 323, 333, 321, 422, 423, 332, 432) THEN 'Active'
		WHEN rfm_cell_string in ( 433, 434, 443, 444) THEN 'Loyal'
	END rfm_segment
FROM #rfm		

---What products are most often sold together?---
SELECT DISTINCT ORDERNUMBER, STUFF(
		(SELECT ',' + PRODUCTCODE
		FROM [dbo].[sales_data_sample] q
		WHERE ORDERNUMBER in (

		SELECT ORDERNUMBER
		FROM (SELECT ORDERNUMBER, COUNT(*) rn
				FROM [dbo].[sales_data_sample]
				WHERE STATUS = 'Shipped'
				GROUP BY ORDERNUMBER
		) p
		WHERE rn = 2
		AND q.ORDERNUMBER = t.ORDERNUMBER
		) for xml path(''))
		,1,1,'') Product_codes
FROM [dbo].[sales_data_sample] t
ORDER  BY 2 DESC