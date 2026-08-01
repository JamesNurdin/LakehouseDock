WITH sales_with_returns AS (
    SELECT
        d.d_year,
        c.c_birth_country,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        sr.sr_net_loss,
        ss.ss_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    WHERE cp.cp_catalog_number = 14
      AND c.c_birth_country = 'KOREA'
      AND d.d_qoy = 1
      AND ss.ss_quantity > 2
      AND ss.ss_ext_sales_price > (SELECT MAX(ssx.ss_ext_sales_price) FROM store_sales ssx)
      AND EXISTS (SELECT 1 FROM store_returns r WHERE r.sr_ticket_number = ss.ss_ticket_number)
      AND NOT EXISTS (SELECT 1 FROM store_returns r2 WHERE r2.sr_customer_sk = c.c_customer_sk AND r2.sr_returned_date_sk = d.d_date_sk)
)
SELECT
    u.d_year,
    u.c_birth_country,
    COUNT(DISTINCT u.ss_ticket_number) AS num_transactions,
    SUM(u.ss_ext_sales_price) AS total_sales,
    AVG(CASE WHEN u.ss_quantity > 5 THEN u.ss_ext_sales_price END) AS avg_large_qty_sales,
    SUM(COALESCE(u.sr_net_loss, 0)) AS total_return_loss
FROM (
    SELECT * FROM sales_with_returns
    UNION
    SELECT
        d.d_year,
        c.c_birth_country,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        sr.sr_net_loss,
        ss.ss_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    WHERE cp.cp_catalog_number = 20
      AND c.c_birth_country = 'REPUBLI​C OF'
      AND d.d_qoy = 2
      AND ss.ss_quantity > 3
      AND ss.ss_ext_sales_price > (SELECT MAX(ssx.ss_ext_sales_price) FROM store_sales ssx)
      AND EXISTS (SELECT 1 FROM store_returns r WHERE r.sr_ticket_number = ss.ss_ticket_number)
      AND NOT EXISTS (SELECT 1 FROM store_returns r2 WHERE r2.sr_customer_sk = c.c_customer_sk AND r2.sr_returned_date_sk = d.d_date_sk)
) u
GROUP BY u.d_year, u.c_birth_country
ORDER BY total_sales DESC
LIMIT 100
