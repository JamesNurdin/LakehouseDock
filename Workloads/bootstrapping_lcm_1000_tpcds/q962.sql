WITH daily_aggregates AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_quarter_name,
        sm.sm_carrier,
        sm.sm_type,
        sm.sm_contract,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(cr.cr_fee) + SUM(wr.wr_fee) AS total_fees,
        AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
        AVG(wr.wr_return_quantity) AS avg_web_return_qty,
        COUNT(DISTINCT s.s_store_id) AS stores_closed
    FROM date_dim d
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
    GROUP BY d.d_date_sk, d.d_year, d.d_quarter_name, sm.sm_carrier, sm.sm_type, sm.sm_contract
)
SELECT
    d_year,
    d_quarter_name,
    sm_carrier,
    sm_type,
    sm_contract,
    catalog_return_orders,
    web_return_orders,
    catalog_net_loss,
    web_net_loss,
    total_fees,
    avg_catalog_return_qty,
    avg_web_return_qty,
    stores_closed,
    CASE WHEN web_net_loss <> 0 THEN catalog_net_loss / web_net_loss ELSE NULL END AS catalog_to_web_loss_ratio,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (catalog_net_loss + web_net_loss) DESC) AS loss_rank
FROM daily_aggregates
ORDER BY loss_rank, d_year
LIMIT 100
