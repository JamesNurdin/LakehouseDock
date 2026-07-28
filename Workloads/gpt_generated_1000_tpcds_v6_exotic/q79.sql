WITH sales_by_site AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        d.d_year,
        d.d_month_seq,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_bill_customer_sk AS c_customer_sk,
        sw.web_name,
        sw.web_city,
        c.c_salutation,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REGEXP_EXTRACT(sw.web_name, '(\\d+)$') AS site_number_suffix
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_site sw ON ws.ws_web_site_sk = sw.web_site_sk
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE REGEXP_LIKE(sw.web_city, '^San|^Los')
      AND sw.web_name LIKE '%Online%'
)
SELECT
    COALESCE(CAST(sbs.d_year AS VARCHAR), 'All Years') AS year,
    COALESCE(CAST(sbs.d_month_seq AS VARCHAR), 'All Months') AS month,
    CASE
        WHEN AVG(sbs.ws_net_profit) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_category,
    COUNT(DISTINCT sbs.ws_order_number) AS orders,
    SUM(sbs.ws_ext_sales_price) AS total_sales,
    SUM(sbs.ws_quantity) AS total_quantity,
    AVG(sbs.ws_net_profit) AS avg_profit,
    COUNT(DISTINCT sbs.c_customer_sk) AS unique_customers
FROM sales_by_site sbs
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.catalog_returns cr
    WHERE cr.cr_order_number = sbs.ws_order_number
)
GROUP BY GROUPING SETS (
    (sbs.d_year, sbs.d_month_seq),
    (sbs.d_year),
    ()
)
ORDER BY year ASC, month ASC
LIMIT 100
