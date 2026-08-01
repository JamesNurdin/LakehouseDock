WITH warehouse_sales AS (
   SELECT
     w.w_warehouse_id,
     w.w_county,
     SUM(ws.ws_ext_sales_price) AS total_sales,
     SUM(ws.ws_net_profit) AS total_profit,
     COUNT(*) AS sales_count,
     AVG(ws.ws_quantity) AS avg_quantity,
     SUM(ws.ws_ext_tax) AS total_tax,
     SUM(ws.ws_ext_sales_price) * 0.1 AS estimated_commission
   FROM web_sales ws
   JOIN warehouse w
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN web_returns wr
     ON wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
   WHERE
     w.w_county IN ('Bronx County', 'Mobile County')
     AND w.w_state = 'NY'
     AND ws.ws_ext_tax > 10.0
     AND ws.ws_quantity >= 2
     AND wr.wr_account_credit > 50.0
     AND wr.wr_return_ship_cost BETWEEN 50 AND 200
   GROUP BY
     w.w_warehouse_id,
     w.w_county
)
SELECT
   ws.w_warehouse_id,
   ws.w_county,
   ws.total_sales,
   ws.total_profit,
   ws.sales_count,
   ws.avg_quantity,
   CASE WHEN ws.total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
   (SELECT AVG(total_profit) FROM warehouse_sales) AS avg_warehouse_profit,
   ws.estimated_commission
FROM warehouse_sales ws
WHERE ws.total_sales > (SELECT AVG(total_sales) FROM warehouse_sales)
ORDER BY ws.total_profit DESC, ws.total_sales DESC
LIMIT 100
