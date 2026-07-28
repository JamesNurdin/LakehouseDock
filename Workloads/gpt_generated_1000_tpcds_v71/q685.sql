WITH sales_no_return AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit
    FROM store_sales ss
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
          AND sr.sr_item_sk = ss.ss_item_sk
    )
)
SELECT
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    CONCAT(s.s_store_name, ' - ', i.i_product_name) AS store_product,
    regexp_extract(ca.ca_zip, '(\\d{3})', 1) AS zip_prefix,
    SUM(ssnr.ss_quantity) AS total_quantity,
    SUM(ssnr.ss_ext_sales_price) AS total_sales,
    SUM(ssnr.ss_net_profit) AS total_profit,
    CASE
        WHEN SUM(ssnr.ss_net_profit) / NULLIF(SUM(ssnr.ss_ext_sales_price), 0) > 0.2 THEN 'High'
        ELSE 'Low'
    END AS profit_category
FROM sales_no_return ssnr
JOIN date_dim d ON ssnr.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ssnr.ss_sold_time_sk = t.t_time_sk
JOIN item i ON ssnr.ss_item_sk = i.i_item_sk
JOIN store s ON ssnr.ss_store_sk = s.s_store_sk
JOIN customer_address ca ON ssnr.ss_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2022
  AND regexp_like(ca.ca_suite_number, '^Suite [A-Z]$')
  AND s.s_store_name LIKE '%Market%'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    CONCAT(s.s_store_name, ' - ', i.i_product_name),
    regexp_extract(ca.ca_zip, '(\\d{3})', 1)
HAVING SUM(ssnr.ss_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
