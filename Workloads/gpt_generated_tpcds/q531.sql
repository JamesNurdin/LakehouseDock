-- Net profit per store after returns for the year 2001, ranked within each month
WITH monthly_store_profit AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
        SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) AS net_profit_after_returns
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
    WHERE d.d_date >= DATE '2001-01-01' 
      AND d.d_date < DATE '2002-01-01'
    GROUP BY d.d_year, d.d_month_seq, s.s_store_name
)
SELECT
    m.d_year,
    m.d_month_seq,
    m.s_store_name,
    m.total_net_profit,
    m.total_return_loss,
    m.net_profit_after_returns,
    RANK() OVER (PARTITION BY m.d_year, m.d_month_seq ORDER BY m.net_profit_after_returns DESC) AS store_rank_in_month
FROM monthly_store_profit m
WHERE m.net_profit_after_returns > 0
ORDER BY m.d_year, m.d_month_seq, store_rank_in_month
