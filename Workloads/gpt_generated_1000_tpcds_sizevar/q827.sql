WITH store_full AS (
   SELECT
     s.s_store_sk,
     s.s_store_name,
     s.s_state,
     sr.sr_item_sk,
     sr.sr_return_amt,
     sr.sr_customer_sk
   FROM store s
   FULL OUTER JOIN store_returns sr
     ON s.s_store_sk = sr.sr_store_sk
),
catalog_data AS (
   SELECT
     cs.cs_order_number,
     cs.cs_item_sk,
     cs.cs_warehouse_sk,
     cs.cs_bill_customer_sk,
     cs.cs_bill_cdemo_sk,
     cs.cs_quantity,
     cs.cs_net_paid,
     cs.cs_net_profit,
     i.i_item_id,
     i.i_brand,
     i.i_category,
     w.w_warehouse_name,
     c.c_first_name,
     c.c_last_name,
     cd.cd_gender,
     cd.cd_marital_status
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   WHERE cs.cs_quantity >= 2
     AND cs.cs_net_paid >= 150.00
     AND i.i_category = 'Electronics'
)
SELECT
  cd.cs_order_number,
  cd.i_item_id,
  cd.i_brand,
  cd.i_category,
  cd.w_warehouse_name,
  cd.c_first_name,
  cd.c_last_name,
  cd.cd_gender,
  cd.cd_marital_status,
  COUNT(DISTINCT sf.s_store_sk) AS store_count,
  SUM(cd.cs_quantity) AS total_quantity,
  SUM(cd.cs_net_paid) AS total_net_paid,
  AVG(cd.cs_net_profit) AS avg_net_profit,
  (SELECT COALESCE(SUM(sr2.sr_return_amt), 0)
   FROM store_returns sr2
   WHERE sr2.sr_item_sk = cd.cs_item_sk) AS total_return_amount,
  CASE WHEN EXISTS (
        SELECT 1 FROM inventory inv
        WHERE inv.inv_item_sk = cd.cs_item_sk
          AND inv.inv_quantity_on_hand > 0
      ) THEN 1 ELSE 0 END AS in_stock_flag,
  CASE WHEN EXISTS (
        SELECT 1 FROM web_sales ws
        WHERE ws.ws_item_sk = cd.cs_item_sk
          AND ws.ws_bill_customer_sk = cd.cs_bill_customer_sk
          AND ws.ws_net_paid > 200
      ) THEN 'Yes' ELSE 'No' END AS has_high_web_sales
FROM catalog_data cd
LEFT JOIN store_full sf ON sf.sr_item_sk = cd.cs_item_sk
LEFT JOIN inventory inv ON inv.inv_item_sk = cd.cs_item_sk
  AND inv.inv_warehouse_sk = cd.cs_warehouse_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = cd.cs_item_sk
  AND ws.ws_bill_customer_sk = cd.cs_bill_customer_sk
GROUP BY
  cd.cs_order_number,
  cd.i_item_id,
  cd.i_brand,
  cd.i_category,
  cd.w_warehouse_name,
  cd.c_first_name,
  cd.c_last_name,
  cd.cd_gender,
  cd.cd_marital_status,
  cd.cs_item_sk,
  cd.cs_warehouse_sk,
  cd.cs_bill_customer_sk
HAVING SUM(cd.cs_net_paid) > 5000
ORDER BY total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
