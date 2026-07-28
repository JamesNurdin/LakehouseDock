WITH sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
),
returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
)
SELECT
    s.s_store_name,
    ca_sales.ca_city,
    td_sales.t_hour,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'High'
        ELSE 'Normal'
    END AS sales_category,
    COUNT(DISTINCT ss.ss_ticket_number) AS unique_transactions
FROM sales ss
JOIN time_dim td_sales      ON ss.ss_sold_time_sk = td_sales.t_time_sk               -- join #1
JOIN customer_address ca_sales ON ss.ss_addr_sk = ca_sales.ca_address_sk               -- join #2
JOIN store s               ON ss.ss_store_sk = s.s_store_sk                         -- join #3
JOIN returns sr           ON ss.ss_item_sk = sr.sr_item_sk                         -- join #4
JOIN time_dim td_returns   ON sr.sr_return_time_sk = td_returns.t_time_sk           -- join #5
JOIN customer_address ca_returns ON sr.sr_addr_sk = ca_returns.ca_address_sk        -- join #6
JOIN reason r              ON sr.sr_reason_sk = r.r_reason_sk                       -- join #7
JOIN store s2              ON sr.sr_store_sk = s2.s_store_sk                       -- join #8 (store reused under different alias)
JOIN time_dim td_extra     ON ss.ss_sold_time_sk = td_extra.t_time_sk              -- join #9 (extra alias of time_dim)
WHERE NOT EXISTS (
    SELECT 1
    FROM reason r2
    WHERE r2.r_reason_desc LIKE '%warranty%'
      AND r2.r_reason_sk = sr.sr_reason_sk
)
GROUP BY
    s.s_store_name,
    ca_sales.ca_city,
    td_sales.t_hour
ORDER BY total_sales DESC
LIMIT 100
