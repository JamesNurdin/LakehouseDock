/*
  Analytical query: Net profit after returns for the morning shift (06‑12h)
  – Aggregates sales and returns from the Catalog and Web channels.
  – Groups by Warehouse and Ship‑Mode.
  – Uses only the allowed tables and join relationships.
*/
WITH catalog_sales_agg AS (
    SELECT
        w.w_warehouse_id,
        sm.sm_ship_mode_id,
        SUM(cs.cs_net_paid)   AS sales_amount,
        SUM(cs.cs_net_profit) AS profit_amount,
        0                     AS return_loss
    FROM catalog_sales cs
    JOIN time_dim td   ON cs.cs_sold_time_sk   = td.t_time_sk
    JOIN ship_mode sm  ON cs.cs_ship_mode_sk  = sm.sm_ship_mode_sk
    JOIN warehouse w   ON cs.cs_warehouse_sk  = w.w_warehouse_sk
    WHERE td.t_hour BETWEEN 6 AND 12
    GROUP BY w.w_warehouse_id, sm.sm_ship_mode_id
),
catalog_returns_agg AS (
    SELECT
        w.w_warehouse_id,
        sm.sm_ship_mode_id,
        0                     AS sales_amount,
        0                     AS profit_amount,
        SUM(cr.cr_net_loss)   AS return_loss
    FROM catalog_returns cr
    JOIN time_dim td   ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN ship_mode sm  ON cr.cr_ship_mode_sk    = sm.sm_ship_mode_sk
    JOIN warehouse w   ON cr.cr_warehouse_sk    = w.w_warehouse_sk
    WHERE td.t_hour BETWEEN 6 AND 12
    GROUP BY w.w_warehouse_id, sm.sm_ship_mode_id
),
web_sales_agg AS (
    SELECT
        w.w_warehouse_id,
        sm.sm_ship_mode_id,
        SUM(ws.ws_net_paid)   AS sales_amount,
        SUM(ws.ws_net_profit) AS profit_amount,
        0                     AS return_loss
    FROM web_sales ws
    JOIN time_dim td   ON ws.ws_sold_time_sk   = td.t_time_sk
    JOIN ship_mode sm  ON ws.ws_ship_mode_sk  = sm.sm_ship_mode_sk
    JOIN warehouse w   ON ws.ws_warehouse_sk  = w.w_warehouse_sk
    WHERE td.t_hour BETWEEN 6 AND 12
    GROUP BY w.w_warehouse_id, sm.sm_ship_mode_id
),
web_returns_agg AS (
    SELECT
        w.w_warehouse_id,
        sm.sm_ship_mode_id,
        0                     AS sales_amount,
        0                     AS profit_amount,
        SUM(wr.wr_net_loss)   AS return_loss
    FROM web_returns wr
    JOIN time_dim td   ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_sales ws   ON wr.wr_item_sk      = ws.ws_item_sk
                         AND wr.wr_order_number = ws.ws_order_number
    JOIN ship_mode sm  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w   ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE td.t_hour BETWEEN 6 AND 12
    GROUP BY w.w_warehouse_id, sm.sm_ship_mode_id
)
SELECT
    combined.w_warehouse_id,
    combined.sm_ship_mode_id,
    SUM(combined.sales_amount)   AS total_sales_amount,
    SUM(combined.profit_amount)  AS total_profit_amount,
    SUM(combined.return_loss)    AS total_return_loss,
    SUM(combined.profit_amount) - SUM(combined.return_loss) AS net_profit_after_returns
FROM (
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM catalog_returns_agg
    UNION ALL
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM web_returns_agg
) AS combined
GROUP BY combined.w_warehouse_id, combined.sm_ship_mode_id
ORDER BY net_profit_after_returns DESC
LIMIT 100
