WITH item_wh AS (
    SELECT i.i_item_sk,
           i.i_category,
           i.i_manufact_id,
           w.w_warehouse_sk,
           w.w_warehouse_name
    FROM item i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w   ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY i.i_item_sk,
             i.i_category,
             i.i_manufact_id,
             w.w_warehouse_sk,
             w.w_warehouse_name
)
SELECT record_type,
       item_sk,
       warehouse_sk,
       category,
       warehouse_name,
       total_sales,
       total_profit
FROM (
    SELECT 'sales'   AS record_type,
           cs.cs_item_sk      AS item_sk,
           cs.cs_warehouse_sk AS warehouse_sk,
           iwh.i_category     AS category,
           iwh.w_warehouse_name AS warehouse_name,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           SUM(cs.cs_net_profit)      AS total_profit
    FROM catalog_sales cs
    JOIN item_wh iwh
      ON cs.cs_item_sk = iwh.i_item_sk
     AND cs.cs_warehouse_sk = iwh.w_warehouse_sk
    WHERE cs.cs_ext_list_price > 8000
      AND cs.cs_quantity >= 1
    GROUP BY cs.cs_item_sk,
             cs.cs_warehouse_sk,
             iwh.i_category,
             iwh.w_warehouse_name
    UNION ALL
    SELECT 'returns' AS record_type,
           wr.wr_item_sk      AS item_sk,
           iwh.w_warehouse_sk AS warehouse_sk,
           iwh.i_category     AS category,
           iwh.w_warehouse_name AS warehouse_name,
           -SUM(wr.wr_return_amt) AS total_sales,
           -SUM(wr.wr_net_loss)   AS total_profit
    FROM web_returns wr
    JOIN item_wh iwh
      ON wr.wr_item_sk = iwh.i_item_sk
    WHERE iwh.i_manufact_id = 460
      AND wr.wr_returned_time_sk IN (23325, 72837)
    GROUP BY wr.wr_item_sk,
             iwh.w_warehouse_sk,
             iwh.i_category,
             iwh.w_warehouse_name
) AS combined
ORDER BY total_sales DESC
LIMIT 100
