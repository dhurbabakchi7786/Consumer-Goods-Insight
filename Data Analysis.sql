-- 1. List of markets in which customer "Atliq Exlcusive" operates business in the APAC region
select market
from dim_customer
where customer='Atliq Exclusive' and region='APAC' ;

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? 
with total_products as(
select fiscal_year,count(distinct product_code) as unique_products from fact_sales_monthly
group by fiscal_year )

select  a.unique_products as unique_products_2020,
		b.unique_products as unique_products_2021,
        (b.unique_products-a.unique_products) as increse_unique_products,
        round((b.unique_products-a.unique_products)*100/a.unique_products,1) as pct
from 
total_products as a
join
total_products as b
on a.fiscal_year+1=b.fiscal_year ;

-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts
select segment,count(product_code) as product_count
from dim_product
group by segment
order by product_count desc;

-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
with total_products as (
select segment,fiscal_year,
count(distinct product_code) as uniq
from dim_product d
join fact_sales_monthly f
using(product_code)
group by segment,fiscal_year )

select a.segment,a.uniq as c_2020 ,b.uniq as c_2021,
		(b.uniq-a.uniq) as difference
from total_products as a
join total_products as b
on a.fiscal_year+1=b.fiscal_year and a.segment=b.segment
order by difference desc
limit 1;

-- 5 Get the products that have the highest and lowest manufacturing costs.
select * from 
(select d.product_code,d.product,f.manufacturing_cost
from dim_product d
join 
fact_manufacturing_cost f
on d.product_code=f.product_code
where f.manufacturing_cost=(select max(manufacturing_cost) from fact_manufacturing_cost)) as a
union
(select d.product_code,d.product,f.manufacturing_cost
from dim_product d
join 
fact_manufacturing_cost f
on d.product_code=f.product_code
where f.manufacturing_cost=(select min(manufacturing_cost) from fact_manufacturing_cost));


-- 6.  Generate a report which contains the top 5 customers who received an average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the Indian  market. 
SELECT d.customer_code,d.customer,
 round(fp.pre_invoice_discount_pct*100,2) as Avg_discount_pct
FROM fact_pre_invoice_deductions fp
join 
dim_customer d
on d.customer_code=fp.customer_code
where fp.fiscal_year=2021 and d.market="india"
order by Avg_discount_pct desc
limit 5;

-- 7.  Get the complete report of the Gross sales amount for the customer  “Atliq Exclusive”  for each month  . 
-- This analysis helps to  get an idea of low and high-performing months and take strategic decisions.

SELECT 
month(fs.date) as month,
year(fs.date) as year,
round(sum((fg.gross_price*fs.sold_quantity)),2) as Gross_sales_Amount 
FROM 
fact_gross_price fg
join
fact_sales_monthly fs
on fg.product_code =fs.product_code and fg.fiscal_year=fs.fiscal_year
join 
dim_customer d
on fs.customer_code=d.customer_code
where d.customer="Atliq Exclusive"
group by month,year
order by year,month ;

-- 8.  In which quarter of 2020, got the maximum total_sold_quantity?

with table1 as (
select date,
CASE 
    WHEN MONTH(date) in(9,10,11) THEN 'Q1'
    WHEN MONTH(date) in(12,1,2) THEN 'Q2'
    WHEN MONTH(date) in(3,4,5) AND 5 THEN 'Q3'
    ELSE 'Q4'
END AS fiscal_quarter,
sold_quantity
from fact_sales_monthly
where fiscal_year=2020)

select fiscal_quarter,
concat(cast(round(sum(sold_quantity)/1000000,2)as char),"M") as total_sold_quantity 
from table1
group by fiscal_quarter
order by total_sold_quantity desc;

-- 9.  Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 

with tbl1 as (
SELECT 
d.channel,
round(sum(fg.gross_price*fs.sold_quantity)/1000000,2) as Gross_sales_Amount 
FROM 
fact_gross_price fg
join
fact_sales_monthly fs
on fg.product_code =fs.product_code 
join 
dim_customer d
on fs.customer_code=d.customer_code
where fs.fiscal_year=2021
group by channel )

select *,
round(Gross_sales_Amount*100/sum(Gross_sales_Amount) over() ,2) as Contribution
from tbl1
order by Gross_sales_Amount desc ;



-- 10.  Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?

with tbl as(
SELECT d.division,
d.product_code,
d.product,
sum(f.sold_quantity) as b
FROM fact_sales_monthly f
join 
dim_product d
on d.product_code=f.product_code
where f.fiscal_year=2021
group by d.division,d.product_code,
d.product)

select * from(
select *,
dense_rank() over(partition by division order by b desc ) as rankorder
 from tbl ) as b where rankorder<=3;