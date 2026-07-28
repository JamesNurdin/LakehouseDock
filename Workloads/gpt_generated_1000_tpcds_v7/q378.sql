/*
Goal: Compute total catalog‑sales profit, total web‑sales profit, and total loss from catalog and web returns for each ship‑mode and warehouse combination.
The query joins all seven selected tables, re‑uses the time_dim, ship_mode and warehouse tables under different aliases, and includes more than nine join clauses. The result is limited to the top 100 rows ordered by catalog‑sales profit.
*/
SELECT
    sm_cs.sm_ship_mode_id   AS ship_mode_id,
    wh_cs.w_warehouse_name   AS warehouse_name,
    SUM(cs.cs_net_profit)    AS total_catalog_sales_profit,
    SUM(ws.ws_net_profit)    AS total_web_sales_profit,
    SUM(cr.cr_net_loss)      AS total_catalog_return_loss,
    SUM(wr.wr_net_loss)      AS total_web_return_loss
FROM
    catalog_sales cs
    JOIN time_dim td_cs    ON cs.cs_sold_time_sk      = td_cs.t_time_sk
    JOIN ship_mode sm_cs   ON cs.cs_ship_mode_sk     = sm_cs.sm_ship_mode_sk
    JOIN warehouse wh_cs   ON cs.cs_warehouse_sk      = wh_cs.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_order_number    = cs.cs_order_number
    JOIN time_dim td_cr    ON cr.cr_returned_time_sk = td_cr.t_time_sk
    JOIN ship_mode sm_cr   ON cr.cr_ship_mode_sk      = sm_cr.sm_ship_mode_sk
    JOIN warehouse wh_cr   ON cr.cr_warehouse_sk      = wh_cr.w_warehouse_sk
    JOIN web_sales ws     ON ws.ws_sold_time_sk     = td_cs.t_time_sk
    JOIN ship_mode sm_ws   ON ws.ws_ship_mode_sk      = sm_ws.sm_ship_mode_sk
    JOIN warehouse wh_ws   ON ws.ws_warehouse_sk      = wh_ws.w_warehouse_sk
    JOIN web_returns wr   ON wr.wr_order_number = ws.ws_order_number
                           AND wr.wr_returned_time_sk = td_cs.t_time_sk
    JOIN time_dim td_wr    ON wr.wr_returned_time_sk = td_wr.t_time_sk
WHERE
    td_cs.t_hour BETWEEN 0 AND 23 -- optional filter on time of day
GROUP BY
    sm_cs.sm_ship_mode_id,
    wh_cs.w_warehouse_name
ORDER BY
    total_catalog_sales_profit DESC
LIMIT 100
