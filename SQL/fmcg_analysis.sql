DROP TABLE IF EXISTS fmcg_sales_staging;

CREATE TABLE fmcg_sales_staging (
    Invoice_ID VARCHAR(100),
    Invoice_Date VARCHAR(100),
    City VARCHAR(100),
    Store_Format VARCHAR(100),
    Category VARCHAR(100),
    Brand VARCHAR(100),
    Channel VARCHAR(100),
    Payment_Mode VARCHAR(100),
    Units VARCHAR(100),
    Cost_Price VARCHAR(100),
    Selling_Price VARCHAR(100),
    Revenue VARCHAR(100),
    Cost VARCHAR(100),
    Margin VARCHAR(100),
    Margin_Percent VARCHAR(100),
    Stock_On_Hand VARCHAR(100),
    Reorder_Level VARCHAR(100),
    Lead_Time_Days VARCHAR(100),
    Customer_Age VARCHAR(100),
    Customer_Gender VARCHAR(100),
    Loyalty_Flag VARCHAR(100)
);

select count(*)as stagging_total_row from fmcg_sales_staging;


DROP TABLE IF EXISTS fmcg_sales_clean;

CREATE TABLE fmcg_sales_clean (
    Invoice_ID BIGINT,
    Invoice_Date TIMESTAMP,
    City VARCHAR(50),
    Store_Format VARCHAR(50),
    Category VARCHAR(50),
    Brand VARCHAR(50),
    Channel VARCHAR(50),
    Payment_Mode VARCHAR(50),
    Units INT,
    Cost_Price NUMERIC(12, 4),
    Selling_Price NUMERIC(12, 4),
    Revenue NUMERIC(15, 4),
    Cost NUMERIC(15, 4),
    Margin NUMERIC(15, 4),
    Margin_Percent NUMERIC(10, 6),
    Stock_On_Hand INT,
    Reorder_Level INT,
    Lead_Time_Days INT,
    Customer_Age INT,            
    Customer_Gender VARCHAR(20), 
    Loyalty_Flag INT,
    Order_Month VARCHAR(15),     
    Order_Year INT                
);



INSERT INTO fmcg_sales_clean
SELECT 
    CAST(Invoice_ID AS BIGINT),
    CAST(Invoice_Date AS TIMESTAMP),
    City,
    Store_Format,
    Category,
    Brand,
    Channel,
    Payment_Mode,
    CAST(Units AS INT),
    CAST(Cost_Price AS NUMERIC(12, 4)),
    CAST(Selling_Price AS NUMERIC(12, 4)),
    CAST(Revenue AS NUMERIC(15, 4)),
    CAST(Cost AS NUMERIC(15, 4)),
    CAST(Margin AS NUMERIC(15, 4)),
    CAST(Margin_Percent AS NUMERIC(10, 6)),
    CAST(Stock_On_Hand AS INT),
    CAST(Reorder_Level AS INT),
    CAST(Lead_Time_Days AS INT),
    
    -- Cleaning 1: filling with 35 as requirement
    CASE 
        WHEN Customer_Age IS NULL OR Customer_Age = 'nan' OR Customer_Age = '' THEN 35
        ELSE CAST(FLOOR(CAST(Customer_Age AS NUMERIC)) AS INT)
    END AS Customer_Age,
    
    -- Cleaning 2: 
    CASE 
        WHEN Customer_Gender = 'M' THEN 'Male'
        WHEN Customer_Gender = 'F' THEN 'Female'
        ELSE 'Others'
    END AS Customer_Gender,
    
    CAST(Loyalty_Flag AS INT),
    
    -- Feature Engineering: Date to  Month and Year extracting for MIS
    TO_CHAR(CAST(Invoice_Date AS TIMESTAMP), 'Month') AS Order_Month,
    EXTRACT(YEAR FROM CAST(Invoice_Date AS TIMESTAMP)) AS Order_Year
FROM fmcg_sales_staging;




-- Category Analysis
SELECT
	CATEGORY,
	COUNT(INVOICE_ID) AS ORDERS,
	ROUND(SUM(REVENUE), 2) AS REVENUE,
	ROUND(SUM(MARGIN), 2) AS PROFIT,
	ROUND(SUM(MARGIN) * 100 / SUM(REVENUE), 2) AS PROFIT_MARGIN_PERCENT
FROM
	FMCG_SALES_CLEAN
GROUP BY
	CATEGORY
ORDER BY
	PROFIT DESC;


-- Brand Performance Analysis
SELECT Brand,
	Count(Invoice_ID) AS Orders,
	ROUND(SUM(Revenue), 2) AS Revenue,
	ROUND(SUM(Margin),2) AS Profit,
	ROUND(SUM(Margin)*100.0 / SUM(Revenue),2) AS Margin_Percent
FROM fmcg_sales_clean
group by Brand
order by Revenue desc;


-- Loyalty Analysis
SELECT
	CASE
		WHEN Loyalty_Flag = 1
		THEN 'Loyal Customer'
		ELSE 'Regular Customer'
	END AS Customer_Type,

	COUNT(*) AS Transactions,
	ROUND(SUM(Revenue),2) AS Revenue,
	ROUND(AVG(Revenue),2) AS Avg_Bill_Value,
	ROUND(SUM(Margin),2) AS Profit
FROM fmcg_sales_clean
GROUP BY Customer_Type
ORDER BY Revenue DESC;



-- City Performance Analysis
SELECT
	City,
	COUNT(Invoice_ID) AS Orders,
	ROUND(SUM(Revenue),2) AS Revenue,
	ROUND(SUM(Margin),2) AS Profit,
	ROUND(SUM(Margin)*100.0/SUM(Revenue),2) AS Margin_Percent
FROM fmcg_sales_clean
GROUP BY City
ORDER BY Revenue DESC;


-- Channel Analysis
SELECT 
	Channel,
	COUNT(Invoice_ID) AS Orders,
	ROUND(SUM(Revenue),2) AS Revenue,
	ROUND(SUM(Margin),2) AS Profit,
	ROUND(SUM(Margin)*100.0/SUM(Revenue),2) AS Margin_Percent
FROM fmcg_sales_clean
GROUP BY Channel
ORDER BY Revenue DESC;


-- Inventory Risk Analysis
SELECT 
	Category,
	COUNT(*) AS Products_Below_Reorder,
	ROUND(AVG(Reorder_Level - Stock_On_Hand),2) AS Avg_Stock_Deficit
FROM fmcg_sales_clean
WHERE Stock_On_Hand < Reorder_Level
GROUP BY Category
ORDER BY Products_Below_Reorder DESC;



-- Monthly Trend
SELECT 
	DATE_TRUNC('month',Invoice_Date) AS Month,
	ROUND(SUM(Revenue),2) AS Revenue,
	ROUND(SUM(Margin),2) AS Profit,
	COUNT(Invoice_ID) AS Orders
FROM fmcg_sales_clean
GROUP BY DATE_TRUNC('month',Invoice_Date)
ORDER BY Month;



-- Pareto Analysis
WITH brand_revenue AS 
(
	SELECT 
		Brand,
		SUM(Revenue) AS Revenue
	FROM fmcg_sales_clean
	GROUP BY Brand
),
ranked AS
(
	SELECT
		Brand,
		Revenue,
		SUM(Revenue)OVER(ORDER BY Revenue DESC) AS Running_Revenue,
		SUM(Revenue)OVER() AS Total_Revenue
	FROM brand_revenue
)
SELECT
	Brand,
	ROUND(Revenue,2) AS Revenue,
	ROUND(Running_Revenue * 100.0/Total_Revenue ,2) AS Cumulative_Revenue_Percent
FROM ranked
ORDER BY Revenue DESC;