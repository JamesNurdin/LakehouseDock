WITH sales_agg AS (
    SELECT i.i_category,
           w.w_warehouse_name,
           d.d_year,
           SUM(ws.ws_net_paid) AS total_sales,
           SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY i.i_category, w.w_warehouse_name, d.d_year
),
returns_agg AS (
    SELECT i.i_category,
           w.w_warehouse_name,
           d.d_year,
           cc.cc_name,
           SUM(cr.cr_return_amount) AS total_return_amount,
           SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY i.i_category, w.w_warehouse_name, d.d_year, cc.cc_name
),
inventory_agg AS (
    SELECT i.i_category,
           w.w_warehouse_name,
           d.d_year,
           AVG(inv.inv_quantity_on_hand) AS avg_quantity_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY i.i_category, w.w_warehouse_name, d.d_year
)
SELECT s.i_category AS category,
       s.w_warehouse_name AS warehouse,
       s.d_year AS year,
       s.total_sales,
       s.total_profit,
       r.cc_name AS call_center_name,
       r.total_return_amount,
       r.total_return_loss,
       (s.total_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
       inv.avg_quantity_on_hand
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.i_category = r.i_category
   AND s.w_warehouse_name = r.w_warehouse_name
   AND s.d_year = r.d_year
LEFT JOIN inventory_agg inv
    ON s.i_category = inv.i_category
   AND s.w_warehouse_name = inv.w_warehouse_name
   AND s.d_year = inv.d_year
ORDER BY category, warehouse, year
