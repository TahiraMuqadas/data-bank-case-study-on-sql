select *
from customer;
select *
from region;
select *
from transaction;
1. How many unique nodes are there on the Data Bank system? ;
select  count(distinct node_id) as unique_id
from customer;
2. What is the number of nodes per region? ;
select region.region_name, count(customer.node_id) as number_of_node
from region join customer on region.region_id = customer.region_id
group by region.region_name;
3. How many customers are allocated to each region? ;


SELECT 
    r.region_id,
    r.region_name,
    COUNT(DISTINCT c.customer_id) AS num_customers
FROM customer c
JOIN region r ON c.region_id = r.region_id
GROUP BY r.region_id, r.region_name;
4. How many days on average are customers reallocated to a different node? ;
select round(avg(datediff(end_date, start_id))) average_days_allocation
from customer
where end_date is not null and year(end_date) <> 9999;

5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region? ;
select round(avg(datediff(end_date, start_id))) average_days_allocation
from customer
where end_date is not null and year(end_date) <> 9999;

with rows_ as (
select c.customer_id,
r.region_name, DATEDIFF(c.end_date, c.start_id) AS days_difference,
row_number() over (partition by r.region_name order by DATEDIFF(c.end_date, c.start_id)) AS rows_number,
COUNT(*) over (partition by r.region_name) as total_rows  
from
customer c JOIN region r ON c.region_id = r.region_id
where c.end_date not like '%9999%'
)
SELECT region_name,
ROUND(AVG(CASE WHEN rows_number between (total_rows/2) and ((total_rows/2)+1) THEN days_difference END), 0) AS Median,
MAX(CASE WHEN rows_number = round((0.80 * total_rows),0) THEN days_difference END) AS Percentile_80th,
MAX(CASE WHEN rows_number = round((0.95 * total_rows),0) THEN days_difference END) AS Percentile_95th
from rows_
group by region_name;

alter table transaction
rename column ï»¿customer_id to customer_id;

B. Customer Transactions
1. What is the unique count and total amount for each transaction type? ;
Select txn_type,
Count(txn_type), Sum(txn_amount)
From transaction
group by txn_type;
2. What is the average total historical deposit counts and amounts for all customers?; 
SELECT
  AVG(Deposit_Count) AS Avg_Deposit_Count,
  AVG(Deposit_Amount) AS Avg_Deposit_Amount
FROM (
  SELECT
    customer_id,
    COUNT(*) AS Deposit_Count,
    SUM(txn_amount) AS Deposit_Amount
  FROM transaction
  WHERE txn_type = 'deposit'
  GROUP BY customer_id
) AS Customer_Deposits;
3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?;

    

SELECT
    YEAR(txn_date) AS year,
    MONTH(txn_date) AS month,
    customer_id,
    COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
    COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) AS purchase_count,
    COUNT(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS withdrawal_count
FROM
    transaction
GROUP BY
    YEAR(txn_date),
    MONTH(txn_date),
    customer_id
HAVING
    deposit_count > 1 AND (purchase_count = 1 OR withdrawal_count = 1);
Select * from transaction;

 4. What is the closing balance for each customer at the end of the month?;
 SELECT
  customer_id,
  EXTRACT(YEAR FROM txn_date) AS year,
  EXTRACT(MONTH FROM txn_date) AS month,
  SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 END) - 
  SUM(CASE WHEN txn_type IN ('purchase', 'withdrawal') THEN txn_amount ELSE 0 END) AS closing_balance
FROM
  transaction
GROUP BY
  customer_id,
  EXTRACT(YEAR FROM txn_date),
  EXTRACT(MONTH FROM txn_date)
ORDER BY
  customer_id,
  year,
  month;
  5. What is the percentage of customers who increase their closing balance by more than 5%? ;
  WITH CustomerBalances AS (
    SELECT
        customer_id,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 END) AS TotalDeposits,
        SUM(CASE WHEN txn_type = 'purchase' THEN txn_amount ELSE 0 END) AS TotalPurchases
    FROM
        transaction
    GROUP BY
        customer_id
),
BalanceChanges AS (
    SELECT
        customer_id,
        TotalDeposits,
        TotalPurchases,
        (TotalDeposits - TotalPurchases) AS NetBalanceChange,
        ((TotalDeposits - TotalPurchases) / NULLIF(TotalDeposits, 0)) * 100 AS PercentageIncrease
    FROM
        CustomerBalances
)

SELECT
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN PercentageIncrease > 5 THEN 1 ELSE 0 END) AS CustomersIncreasedMoreThan5Percent,
    (SUM(CASE WHEN PercentageIncrease > 5 THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) * 100 AS PercentageOfCustomersIncreasedMoreThan5Percent
FROM
    BalanceChanges;
    C. Data Allocation Challenge;
    
     Customer Balance at the End of Each Month:;


select *
from transaction;
customer_running_balance;
select customer_id, txn_amount, sum(txn_amount) over (partition by customer_id order by txn_date)
as customer_balance
from transaction;
    
    ● customer balance at the end of each month;
    select customer_id, extract(month from txn_date) as month, 
    sum(txn_amount) over (partition by customer_id order by extract(month from txn_date)) as customer_balance
    from transaction
    order by customer_id, month;
    ● minimum, average and maximum values of the running balance for each customer ;
   
   with customer_balance as (
    select customer_id, txn_date, sum(txn_amount) over ( partition by customer_id order by txn_date) as running_balance
    from transaction
    )
    select customer_id, min(running_balance) as minimum_balance,
    avg(running_balance) as averag_balance,
    max(running_balance) as maximun_balance
    from customer_balance
    group by customer_id;
    
    
