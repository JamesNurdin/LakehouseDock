WITH sales_returns AS (
   SELECT
       cs.cs_order_number,
       cs.cs_call_center_sk,
       cs.cs_warehouse_sk,
       cs.cs_catalog_page_sk,
       cs.cs_quantity,
       cs.cs_net_profit,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       cr.cr_reason_sk
   FROM catalog_sales cs
   JOIN catalog_returns cr
     ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk = cr.cr_item_sk
),
aggregated AS (
   SELECT
       cc.cc_call_center_id,
       w.w_warehouse_name,
       cp.cp_department,
       cc.cc_state,
       SUM(sr.cs_net_profit)               AS total_net_profit,
       SUM(sr.cr_return_amount)            AS total_return_amount,
       COUNT(*)                            AS transaction_count,
       CASE
           WHEN SUM(sr.cs_net_profit) > 100000 THEN 'HIGH'
           WHEN SUM(sr.cs_net_profit) BETWEEN 50000 AND 100000 THEN 'MEDIUM'
           ELSE 'LOW'
       END                                 AS profit_category
   FROM sales_returns sr
   JOIN call_center cc
     ON sr.cs_call_center_sk = cc.cc_call_center_sk
   JOIN warehouse w
     ON sr.cs_warehouse_sk = w.w_warehouse_sk
   JOIN catalog_page cp
     ON sr.cs_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE
       cc.cc_state = 'CA'                           -- 1
       AND w.w_state = 'CA'                         -- 2
       AND cp.cp_type = 'A'                         -- 3
       AND sr.cs_quantity > 5                       -- 4
       AND sr.cs_net_profit > 0                     -- 5
       AND sr.cr_return_amount > 500                -- 6
       AND sr.cr_reason_sk IN (19, 45, 52)          -- 7
       AND EXISTS (
           SELECT 1
           FROM catalog_returns cr2
           WHERE cr2.cr_order_number = sr.cs_order_number
             AND cr2.cr_return_quantity > 1
       )                                            -- 8 (semi‑join)
   GROUP BY
       cc.cc_call_center_id,
       w.w_warehouse_name,
       cp.cp_department,
       cc.cc_state
)
SELECT
    cc_call_center_id,
    w_warehouse_name,
    cp_department,
    total_net_profit,
    total_return_amount,
    transaction_count,
    profit_category,
    RANK() OVER (PARTITION BY cc_state ORDER BY total_net_profit DESC) AS profit_rank_state,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC)               AS overall_rank
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 100
