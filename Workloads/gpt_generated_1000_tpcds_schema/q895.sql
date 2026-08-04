WITH cs_sample AS (
   SELECT *
   FROM catalog_sales
   TABLESAMPLE BERNOULLI (10)
),
cs_join AS (
   SELECT cs_order_number,
          cs_sold_time_sk,
          cs_bill_customer_sk,
          cs_call_center_sk,
          cs_catalog_page_sk,
          cs_warehouse_sk,
          cs_quantity,
          cs_net_profit
   FROM cs_sample
),
ws AS (
   SELECT ws_order_number,
          ws_sold_time_sk,
          ws_bill_customer_sk,
          ws_web_page_sk,
          ws_warehouse_sk,
          ws_quantity,
          ws_net_profit
   FROM web_sales
),
common_orders AS (
   SELECT cs_order_number AS order_num FROM cs_join
   INTERSECT
   SELECT ws_order_number FROM ws
)
SELECT
   co.order_num,
   cc.cc_name,
   cp.cp_description,
   w.w_warehouse_name,
   t_cs.t_hour AS sold_hour,
   t_ws.t_hour AS shipped_hour,
   cust.c_first_name,
   cust.c_last_name,
   inv.inv_quantity_on_hand,
   CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
   COUNT(*) OVER (PARTITION BY w.w_warehouse_name) AS warehouse_order_cnt,
   reason_word
FROM common_orders co
JOIN cs_join cs            ON cs.cs_order_number = co.order_num
JOIN ws               ws   ON ws.ws_order_number = co.order_num
JOIN call_center      cc   ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page     cp   ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse        w    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim         t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN time_dim         t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN customer         cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
LEFT JOIN inventory   inv  ON inv.inv_warehouse_sk = w.w_warehouse_sk
FULL OUTER JOIN store_returns sr ON sr.sr_customer_sk = cust.c_customer_sk
FULL OUTER JOIN web_returns   wr ON wr.wr_refunded_customer_sk = cust.c_customer_sk
LEFT JOIN reason r ON r.r_reason_sk = COALESCE(sr.sr_reason_sk, wr.wr_reason_sk)
LEFT JOIN LATERAL (
   SELECT word AS reason_word
   FROM UNNEST(split(r.r_reason_desc, ' ')) AS t(word)
) AS unreason ON true
WHERE w.w_state = 'CA'
GROUP BY co.order_num,
         cc.cc_name,
         cp.cp_description,
         w.w_warehouse_name,
         t_cs.t_hour,
         t_ws.t_hour,
         cust.c_first_name,
         cust.c_last_name,
         inv.inv_quantity_on_hand,
         CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END,
         r.r_reason_desc,
         reason_word
ORDER BY co.order_num
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
