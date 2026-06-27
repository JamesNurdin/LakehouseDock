WITH sales_with_dates AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        d_sales.d_date AS sales_date,
        d_cust.d_date AS first_ship_date,
        i.i_brand
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d_cust
        ON c.c_first_shipto_date_sk = d_cust.d_date_sk
    WHERE d_sales.d_year = 2001
      AND d_cust.d_date >= DATE '1999-01-01'
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    i_brand,
    date_format(sales_date, '%Y-%m') AS sales_month,
    sum(ss_ext_sales_price) AS total_sales,
    sum(ss_net_profit) AS total_net_profit,
    avg(ss_ext_discount_amt) AS avg_discount,
    count(distinct ss_customer_sk) AS distinct_customers
FROM sales_with_dates
GROUP BY i_brand, date_format(sales_date, '%Y-%m')
ORDER BY total_net_profit DESC
LIMIT 10
