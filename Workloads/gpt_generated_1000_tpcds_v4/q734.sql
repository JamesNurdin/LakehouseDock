WITH warehouse_city AS (
   SELECT w.w_warehouse_sk,
          w.w_city,
          w.w_state
   FROM warehouse w
   WHERE w.w_country = 'United States'
)
SELECT
   'sale' AS record_type,
   cs.cs_order_number        AS order_number,
   cc.cc_call_center_id      AS call_center_id,
   td.t_hour                 AS hour,
   wc.w_city                 AS city,
   cs.cs_ext_sales_price     AS amount,
   (SELECT MAX(cs2.cs_ext_sales_price)
      FROM catalog_sales cs2
     WHERE cs2.cs_call_center_sk = cs.cs_call_center_sk) AS max_amount_for_center
FROM catalog_sales cs
JOIN call_center cc      ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN time_dim td         ON cs.cs_sold_time_sk   = td.t_time_sk
JOIN warehouse_city wc   ON cs.cs_warehouse_sk  = wc.w_warehouse_sk
WHERE td.t_hour BETWEEN 9 AND 17
  AND cs.cs_ext_sales_price > 100

UNION ALL

SELECT
   'return' AS record_type,
   cr.cr_order_number        AS order_number,
   cc.cc_call_center_id      AS call_center_id,
   td.t_hour                 AS hour,
   wc.w_city                 AS city,
   cr.cr_return_amount       AS amount,
   (SELECT MAX(cr2.cr_return_amount)
      FROM catalog_returns cr2
     WHERE cr2.cr_call_center_sk = cr.cr_call_center_sk) AS max_amount_for_center
FROM catalog_returns cr
JOIN call_center cc      ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN time_dim td         ON cr.cr_returned_time_sk = td.t_time_sk
JOIN warehouse_city wc   ON cr.cr_warehouse_sk   = wc.w_warehouse_sk
WHERE td.t_hour BETWEEN 9 AND 17
  AND cr.cr_return_amount > 50

ORDER BY record_type, max_amount_for_center DESC
LIMIT 100
