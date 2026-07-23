WITH agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_state,
        site.web_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(cr.cr_return_quantity) AS total_return_qty,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        MIN(cr.cr_return_amount) AS min_return_amount,
        MAX(cr.cr_return_amount) AS max_return_amount
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    WHERE cr.cr_refunded_cash > 500
      AND w.w_zip = '89275'
      AND ws.ws_wholesale_cost > 30
    GROUP BY w.w_warehouse_id, w.w_state, site.web_name
)
SELECT
    agg.w_warehouse_id,
    agg.w_state,
    agg.web_name,
    agg.total_return_amount,
    agg.total_net_profit,
    agg.total_return_qty,
    agg.avg_return_amount,
    agg.min_return_amount,
    agg.max_return_amount,
    SUM(agg.total_return_amount) OVER (PARTITION BY agg.w_state ORDER BY agg.w_warehouse_id) AS cum_return_amount_by_state
FROM agg
ORDER BY cum_return_amount_by_state DESC
LIMIT 100
