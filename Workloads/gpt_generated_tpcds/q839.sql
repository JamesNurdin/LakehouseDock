WITH store_hourly AS (
    SELECT
        s.s_store_name AS s_store_name,
        t.t_hour AS t_hour,
        sum(ss.ss_net_profit) AS total_sales_profit,
        sum(coalesce(sr.sr_net_loss, 0)) AS total_return_loss,
        count(*) AS sales_transactions,
        count(sr.sr_ticket_number) AS return_transactions
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_return_time_sk = t.t_time_sk
       AND sr.sr_store_sk = s.s_store_sk
    GROUP BY s.s_store_name, t.t_hour
)
SELECT
    s_store_name,
    t_hour,
    total_sales_profit,
    total_return_loss,
    total_sales_profit - total_return_loss AS net_profit_after_returns,
    sales_transactions,
    return_transactions,
    rank() OVER (ORDER BY total_sales_profit - total_return_loss DESC) AS profit_rank
FROM store_hourly
ORDER BY net_profit_after_returns DESC
LIMIT 20
