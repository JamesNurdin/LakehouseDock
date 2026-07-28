WITH recent_dates AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_year = 2002
)

SELECT
    customer.c_customer_id,
    recent_dates.d_year,
    SUM(store_sales.ss_net_paid) AS total_net_paid,
    SUM(store_sales.ss_net_profit) AS total_profit,
    CASE WHEN SUM(store_sales.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    'store' AS sales_source
FROM store_sales
JOIN recent_dates
    ON store_sales.ss_sold_date_sk = recent_dates.d_date_sk
JOIN time_dim
    ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
JOIN customer
    ON store_sales.ss_customer_sk = customer.c_customer_sk
GROUP BY
    customer.c_customer_id,
    recent_dates.d_year

UNION ALL

SELECT
    customer.c_customer_id,
    recent_dates.d_year,
    SUM(catalog_sales.cs_net_paid) AS total_net_paid,
    SUM(catalog_sales.cs_net_profit) AS total_profit,
    CASE WHEN SUM(catalog_sales.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    'catalog' AS sales_source
FROM catalog_sales
JOIN recent_dates
    ON catalog_sales.cs_sold_date_sk = recent_dates.d_date_sk
JOIN time_dim
    ON catalog_sales.cs_sold_time_sk = time_dim.t_time_sk
JOIN customer
    ON catalog_sales.cs_bill_customer_sk = customer.c_customer_sk
JOIN catalog_page
    ON catalog_sales.cs_catalog_page_sk = catalog_page.cp_catalog_page_sk
WHERE catalog_page.cp_catalog_number > 10
GROUP BY
    customer.c_customer_id,
    recent_dates.d_year

LIMIT 100
