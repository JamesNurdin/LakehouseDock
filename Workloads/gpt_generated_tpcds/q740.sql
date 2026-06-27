WITH sales AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2022-01-01'
      AND d.d_date < DATE '2023-01-01'
),
returns AS (
    SELECT
        sr.sr_store_sk,
        d.d_year,
        d.d_month_seq,
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2022-01-01'
      AND d.d_date < DATE '2023-01-01'
)
SELECT
    s.s_store_name,
    s.d_year,
    s.d_month_seq,
    SUM(s.ss_net_profit) AS total_sales_profit,
    COALESCE(SUM(r.sr_net_loss), 0) AS total_return_loss,
    SUM(s.ss_net_profit) - COALESCE(SUM(r.sr_net_loss), 0) AS net_profit_after_returns
FROM sales s
LEFT JOIN returns r
    ON s.ss_store_sk = r.sr_store_sk
   AND s.ss_ticket_number = r.sr_ticket_number
   AND s.ss_item_sk = r.sr_item_sk
   AND s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
GROUP BY s.s_store_name, s.d_year, s.d_month_seq
ORDER BY net_profit_after_returns DESC
LIMIT 10
