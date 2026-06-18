-- SECTION 1: SETUP & DATA VALIDATION
SELECT *
FROM sys.schemas
WHERE name = 'Banking';

-- Step 1A: Move the table to the Banking schema
ALTER SCHEMA Banking
TRANSFER dbo.CreditCardData;

-- Step 1B: Preview the first 10 rows
SELECT TOP 10 *
FROM Banking.CreditCardData;

-- Step 1C: Check total number of rows
SELECT COUNT(*) as TotalRows
FROM Banking.CreditCardData


-- Step 1D: Check for NULL values in important columns
SELECT *
FROM  Banking.CreditCardData
WHERE Income_Category IS NULL;

-- Step 1E: Check for duplicate customers
SELECT CLIENTNUM,COUNT(*) as Occurences
FROM Banking.CreditCardData
GROUP BY CLIENTNUM
HAVING COUNT(*) > 1;

-- SECTION 2: BUSINESS KPIs

-- KPI 1: Total Customers
SELECT COUNT(*) AS TotalCustomers
FROM Banking.CreditCardData

-- KPI 2: Total Churned Customers (customers who left)
SELECT COUNT(*) AS ChurnedCustomers
FROM Banking.CreditCardData
WHERE Attrition_Flag='Attrited Customer';

-- KPI 3: Total Transaction Volume
SELECT
SUM(Total_Trans_Amt) AS Total_Transaction_Volume
FROM Banking.CreditCardData;

-- KPI 4: Average Credit Limit across all customers
SELECT ROUND(AVG(Credit_Limit), 2) AS Avg_Credit_Limit
FROM Banking.CreditCardData;

-- SECTION 3: CHURN RATE

SELECT
    COUNT(*) AS TotalCustomers,
 
    -- Count only churned customers using CASE WHEN
    SUM(
        CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END
    ) AS ChurnedCustomers,
 
    -- Calculate churn rate as a percentage, rounded to 2 decimal places
    ROUND(
        100.0 *
        SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS ChurnRate_Pct
 
FROM Banking.CreditCardData;

-- SECTION 4: CUSTOMER SEGMENTATION BY CARD & INCOME
-- Segmentation 4A: By Card Category with Churn Rate
SELECT
    Card_Category,COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS Churned,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS ChurnRate_Pct
FROM Banking.CreditCardData
GROUP BY Card_Category
ORDER BY TotalCustomers DESC;

-- Segmentation 4B: By Income Category with Churn Rate
 
SELECT
    Income_Category,COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS Churned,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS ChurnRate_Pct
FROM Banking.CreditCardData
GROUP BY Income_Category
ORDER BY ChurnRate_Pct DESC;

-- SECTION 5: DEMOGRAPHIC ANALYSIS
-- Demographics 5A: Gender Analysis
 
SELECT
    Gender,
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS Churned,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS ChurnRate_Pct,
    ROUND(AVG(Total_Trans_Amt), 2) AS Avg_Spending,
    ROUND(AVG(Credit_Limit), 2) AS Avg_Credit_Limit
FROM Banking.CreditCardData
GROUP BY Gender;

-- Demographics 5B: Age Group Analysis
SELECT
    CASE
        WHEN Customer_Age < 30              THEN 'Under 30'
        WHEN Customer_Age BETWEEN 30 AND 45 THEN '30 to 45'
        WHEN Customer_Age BETWEEN 46 AND 60 THEN '46 to 60'
        ELSE                                     'Above 60'
    END AS Age_Group,
 
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS Churned,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS ChurnRate_Pct,
    ROUND(AVG(Credit_Limit), 2) AS Avg_Credit_Limit
 
FROM Banking.CreditCardData
GROUP BY
    CASE
        WHEN Customer_Age < 30              THEN 'Under 30'
        WHEN Customer_Age BETWEEN 30 AND 45 THEN '30 to 45'
        WHEN Customer_Age BETWEEN 46 AND 60 THEN '46 to 60'
        ELSE                                     'Above 60'
    END
ORDER BY TotalCustomers DESC;

-- SECTION 6: BEHAVIORAL ANALYSIS
-- Behavioral 6A: Inactivity vs Churn
 
SELECT
    Months_Inactive_12_mon,COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS Churned,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS ChurnRate_Pct
FROM Banking.CreditCardData
GROUP BY Months_Inactive_12_mon
ORDER BY Months_Inactive_12_mon;

-- Behavioral 6B: Bank Contact Count vs Churn
 
SELECT
    Contacts_Count_12_mon, COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS Churned,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS ChurnRate_Pct
FROM Banking.CreditCardData
GROUP BY Contacts_Count_12_mon
ORDER BY Contacts_Count_12_mon;

-- SECTION 7: CREDIT RISK SEGMENTATION
WITH CreditRiskCTE AS
(
    SELECT CLIENTNUM,Attrition_Flag,Credit_Limit,Total_Revolving_Bal,Avg_Utilization_Ratio,
 
        -- Label each customer based on their utilization
        CASE
            WHEN Avg_Utilization_Ratio >= 0.75              THEN 'High Risk'
            WHEN Avg_Utilization_Ratio BETWEEN 0.40 AND 0.74 THEN 'Medium Risk'
            ELSE                                                  'Low Risk'
        END AS Risk_Segment
 
    FROM Banking.CreditCardData
)
-- Now aggregate the results from the CTE
SELECT
    Risk_Segment,COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS Churned,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS ChurnRate_Pct,
    ROUND(AVG(Credit_Limit), 2) AS Avg_Credit_Limit,
    ROUND(AVG(Total_Revolving_Bal), 2) AS Avg_Revolving_Balance
 
FROM CreditRiskCTE
GROUP BY Risk_Segment
ORDER BY ChurnRate_Pct DESC;

-- SECTION 8: LOYALTY / TENURE ANALYSIS
SELECT
    CASE
        WHEN Months_on_book <= 24                    THEN '0-2 Years'
        WHEN Months_on_book BETWEEN 25 AND 48        THEN '2-4 Years'
        ELSE                                              '4+ Years'
    END AS Tenure_Group,
 
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS Churned,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS ChurnRate_Pct
 
FROM Banking.CreditCardData
GROUP BY
    CASE
        WHEN Months_on_book <= 24                    THEN '0-2 Years'
        WHEN Months_on_book BETWEEN 25 AND 48        THEN '2-4 Years'
        ELSE                                              '4+ Years'
    END
ORDER BY ChurnRate_Pct DESC;


-- Window Function 9A: RANK - Rank customers by spending (highest = Rank 1)
SELECT TOP 20
    CLIENTNUM,
    Attrition_Flag,
    Total_Trans_Amt,
    RANK() OVER (ORDER BY Total_Trans_Amt DESC) AS SpendingRank
FROM Banking.CreditCardData;


-- Window Function 9B: NTILE - Divide customers into 4 spending quartiles
SELECT
    CLIENTNUM,
    Attrition_Flag,
    Total_Trans_Amt,
    NTILE(4) OVER (ORDER BY Total_Trans_Amt DESC) AS SpendingQuartile
FROM Banking.CreditCardData;

-- NTILE Summary: Churn rate by spending quartile (actionable insight)
 
WITH SpendingSegments AS
(
    SELECT
        CLIENTNUM,
        Attrition_Flag,
        Total_Trans_Amt,
        NTILE(4) OVER (ORDER BY Total_Trans_Amt DESC) AS SpendingQuartile
    FROM Banking.CreditCardData
)

SELECT
    SpendingQuartile,
    Attrition_Flag,
    COUNT(*) AS Customers
FROM SpendingSegments
GROUP BY SpendingQuartile, Attrition_Flag
ORDER BY SpendingQuartile, Attrition_Flag;

-- SECTION 10: AVERAGE UTILIZATION RATIO
SELECT
    ROUND(AVG(Avg_Utilization_Ratio), 4) AS Overall_Avg_Utilization,
    ROUND(MIN(Avg_Utilization_Ratio), 4) AS Min_Utilization,
    ROUND(MAX(Avg_Utilization_Ratio), 4) AS Max_Utilization
FROM Banking.CreditCardData;
 