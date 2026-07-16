WITH aggregated AS (
    SELECT
        s.s_store_name AS store_name,
        d_closed.d_year AS store_closed_year,
        COUNT(DISTINCT cs.cs_order_number) AS num_sales_orders,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COUNT(DISTINCT cr.cr_order_number) AS num_return_orders,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_store_returns,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) - SUM(sr.sr_net_loss) AS net_contribution
    FROM store s
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d_sr.d_date_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = cr.cr_item_sk
        AND cs.cs_order_number = cr.cr_order_number
    JOIN date_dim d_cs_sold
        ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN date_dim d_cs_ship
        ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
    WHERE d_closed.d_year = 2001
    GROUP BY s.s_store_name, d_closed.d_year
)
SELECT
    store_name,
    store_closed_year,
    num_sales_orders,
    total_sales_profit,
    num_return_orders,
    total_return_loss,
    num_store_returns,
    total_store_return_loss,
    net_contribution,
    ROW_NUMBER() OVER (PARTITION BY store_closed_year ORDER BY net_contribution DESC) AS net_contribution_rank
FROM aggregated
ORDER BY net_contribution DESC
LIMIT 100
