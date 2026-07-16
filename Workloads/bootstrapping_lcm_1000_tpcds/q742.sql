WITH daily_store_metrics AS (
    SELECT
        d.d_date,
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_sales_net_profit,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        (SUM(ss.ss_net_profit) - SUM(cr.cr_net_loss) - SUM(sr.sr_net_loss)) AS net_profit_after_all_returns
    FROM date_dim d
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
       AND ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
       AND sr.sr_store_sk = s.s_store_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date, s.s_store_id, s.s_store_name
)
SELECT
    d_date,
    s_store_id,
    s_store_name,
    total_sales_net_profit,
    total_quantity_sold,
    total_catalog_return_loss,
    total_store_return_loss,
    net_profit_after_all_returns,
    RANK() OVER (ORDER BY net_profit_after_all_returns DESC) AS profit_rank
FROM daily_store_metrics
ORDER BY profit_rank
LIMIT 100
