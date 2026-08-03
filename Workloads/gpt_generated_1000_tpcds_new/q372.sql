WITH sampled_inventory AS (
       SELECT inv_item_sk,
              inv_warehouse_sk,
              inv_quantity_on_hand
       FROM inventory TABLESAMPLE BERNOULLI (10)
   ),
   warehouse_inventory AS (
       SELECT w.w_warehouse_sk,
              w.w_state,
              i.inv_item_sk,
              i.inv_quantity_on_hand
       FROM sampled_inventory i
       JOIN warehouse w
         ON i.inv_warehouse_sk = w.w_warehouse_sk
   ),
   sales_agg AS (
       SELECT w.w_state,
              cd.cd_gender,
              SUM(ws.ws_ext_sales_price) AS total_sales,
              SUM(ws.ws_net_profit)      AS total_profit,
              COUNT(*)                  AS sales_cnt,
              CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
       FROM web_sales ws
       JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
       JOIN warehouse w               ON ws.ws_warehouse_sk = w.w_warehouse_sk
       WHERE ws.ws_quantity > 0
       GROUP BY CUBE (w.w_state, cd.cd_gender)
   ),
   returns_agg AS (
       SELECT w.w_state,
              cd.cd_gender,
              SUM(cr.cr_return_amount) AS total_return,
              COUNT(*)                 AS return_cnt,
              CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level
       FROM catalog_returns cr
       JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
       JOIN warehouse w               ON cr.cr_warehouse_sk = w.w_warehouse_sk
       WHERE cr.cr_return_quantity > 0
       GROUP BY CUBE (w.w_state, cd.cd_gender)
   ),
   intersect_keys AS (
       SELECT w_state, cd_gender
       FROM sales_agg
       INTERSECT
       SELECT w_state, cd_gender
       FROM returns_agg
   ),
   except_keys AS (
       SELECT w_state, cd_gender
       FROM sales_agg
       EXCEPT
       SELECT w_state, cd_gender
       FROM returns_agg
   ),
   final_set AS (
       SELECT 'INTERSECT' AS set_type, ik.w_state, ik.cd_gender
       FROM intersect_keys ik
       UNION ALL
       SELECT 'EXCEPT' AS set_type, ek.w_state, ek.cd_gender
       FROM except_keys ek
   )
SELECT set_type,
       w_state,
       cd_gender
FROM final_set
ORDER BY set_type, w_state, cd_gender
