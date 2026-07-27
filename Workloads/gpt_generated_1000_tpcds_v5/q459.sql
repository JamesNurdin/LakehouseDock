WITH sales_cte AS (
    SELECT
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        ss.ss_customer_sk,
        ca.ca_location_type,
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_zip,
        ca.ca_address_sk,
        td.t_shift
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE regexp_like(ca.ca_address_id, '^A{7}A')
      AND ca.ca_city LIKE '%ville%'
)
SELECT
    ca_location_type,
    t_shift,
    CASE
        WHEN SUM(ss_net_profit) > 200000 THEN 'High'
        WHEN SUM(ss_net_profit) > 100000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    COUNT(*) AS sales_cnt,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_net_profit) AS avg_profit,
    SUBSTR(ca_zip, 1, 3) AS zip_prefix,
    (SELECT MAX(ss_ext_sales_price) FROM store_sales) AS max_sales_price_overall
FROM sales_cte
WHERE EXISTS (
    SELECT 1
    FROM store_sales s2
    WHERE s2.ss_customer_sk = sales_cte.ss_customer_sk
      AND s2.ss_sold_date_sk BETWEEN 2451000 AND 2452000
)
GROUP BY ca_location_type, t_shift, SUBSTR(ca_zip, 1, 3)
ORDER BY total_sales DESC
LIMIT 100
