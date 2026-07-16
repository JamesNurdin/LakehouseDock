WITH inv_agg AS (
    SELECT i.inv_warehouse_sk,
           d.d_fy_quarter_seq,
           SUM(i.inv_quantity_on_hand) AS total_inv_qty
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1900
    GROUP BY i.inv_warehouse_sk, d.d_fy_quarter_seq
),
sales_agg AS (
    SELECT ws.ws_warehouse_sk,
           d_sold.d_fy_quarter_seq,
           SUM(ws.ws_net_profit) AS total_net_profit,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_delay
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_fy_year = 1900
    GROUP BY ws.ws_warehouse_sk, d_sold.d_fy_quarter_seq
)
SELECT s.d_fy_quarter_seq AS quarter_seq,
       s.ws_warehouse_sk AS warehouse_id,
       s.total_net_profit,
       s.total_quantity,
       s.total_sales,
       i.total_inv_qty,
       s.total_net_profit / NULLIF(s.total_quantity, 0) AS profit_per_unit,
       s.total_net_profit / NULLIF(i.total_inv_qty, 0) AS profit_per_inventory,
       s.avg_shipping_delay,
       RANK() OVER (PARTITION BY s.d_fy_quarter_seq ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN inv_agg i
  ON s.ws_warehouse_sk = i.inv_warehouse_sk
  AND s.d_fy_quarter_seq = i.d_fy_quarter_seq
WHERE s.total_net_profit > 0
ORDER BY quarter_seq, profit_rank
LIMIT 50
