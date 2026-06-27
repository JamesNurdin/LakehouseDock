WITH sales_by_warehouse AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(cs.cs_net_paid)      AS total_sales,
        SUM(cs.cs_net_profit)    AS total_profit
    FROM catalog_sales cs
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name
),
returns_by_warehouse AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss)      AS total_return_loss
    FROM catalog_returns cr
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name
),
inventory_by_warehouse AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(i.inv_quantity_on_hand) AS total_on_hand
    FROM inventory i
    JOIN warehouse w
      ON i.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name
),
web_sales_by_warehouse AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(ws.ws_net_paid)   AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM web_sales ws
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name
)
SELECT
    s.w_warehouse_id,
    s.w_warehouse_name,
    s.total_sales,
    s.total_profit,
    r.total_return_amount,
    r.total_return_loss,
    i.total_on_hand,
    w.total_web_sales,
    w.total_web_profit,
    (s.total_profit - COALESCE(r.total_return_loss, 0) + COALESCE(w.total_web_profit, 0)) AS net_profit_after_returns
FROM sales_by_warehouse s
LEFT JOIN returns_by_warehouse r
  ON s.w_warehouse_id = r.w_warehouse_id
LEFT JOIN inventory_by_warehouse i
  ON s.w_warehouse_id = i.w_warehouse_id
LEFT JOIN web_sales_by_warehouse w
  ON s.w_warehouse_id = w.w_warehouse_id
ORDER BY s.total_sales DESC
LIMIT 20
