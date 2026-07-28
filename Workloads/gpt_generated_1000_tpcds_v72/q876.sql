/*
Goal: Summarize the net paid and net profit from catalog sales that have matching catalog returns, filtering for dates whose IDs match a specific pattern and days starting with 'S'. The query excludes orders that have a store return (anti‑join) but includes orders that have a web return, uses string functions (REGEXP_LIKE, CONCAT), a scalar subquery for average profit, counts distinct order numbers, and limits the result to the top 100 rows.
*/
WITH sales_with_returns AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_item_sk,
        d.d_year,
        d.d_month_seq,
        d.d_date_id,
        d.d_day_name
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_item_sk = cr.cr_item_sk
        AND cs.cs_order_number = cr.cr_order_number
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE REGEXP_LIKE(d.d_date_id, '^AAAAAAA[AL]')
      AND d.d_day_name LIKE 'S%'
)
SELECT
    swr.d_year,
    swr.d_month_seq,
    SUM(swr.cs_net_paid) AS total_net_paid,
    SUM(swr.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT swr.cs_order_number) AS distinct_orders,
    CONCAT('Year-', CAST(swr.d_year AS VARCHAR), '-Month-', CAST(swr.d_month_seq AS VARCHAR)) AS year_month_label
FROM sales_with_returns swr
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_ticket_number = swr.cs_order_number
)
  AND EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_order_number = swr.cs_order_number
)
GROUP BY swr.d_year, swr.d_month_seq
HAVING SUM(swr.cs_net_profit) > (
    SELECT AVG(cs.cs_net_profit)
    FROM catalog_sales cs
)
ORDER BY total_net_paid DESC
LIMIT 100
