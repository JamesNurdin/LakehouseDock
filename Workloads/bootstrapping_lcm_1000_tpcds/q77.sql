WITH daily_metrics AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_current_month,
        SUM(cs.cs_net_profit) AS total_sales_net_profit,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        COUNT(DISTINCT s.s_store_sk) AS stores_closed,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_count
    FROM date_dim d
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN store s
        ON s.s_store_sk = sr.sr_store_sk
        AND s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_item_sk = cr.cr_item_sk
        AND cs.cs_order_number = cr.cr_order_number
    GROUP BY
        d.d_date,
        d.d_year,
        d.d_current_month
)
SELECT
    d_date,
    d_year,
    d_current_month,
    total_sales_net_profit,
    total_catalog_net_loss,
    total_store_net_loss,
    stores_closed,
    store_return_count,
    catalog_return_count,
    (total_sales_net_profit - (total_catalog_net_loss + total_store_net_loss)) AS net_effect,
    ROW_NUMBER() OVER (ORDER BY (total_sales_net_profit - (total_catalog_net_loss + total_store_net_loss)) DESC) AS net_effect_rank
FROM daily_metrics
ORDER BY net_effect DESC
LIMIT 100
