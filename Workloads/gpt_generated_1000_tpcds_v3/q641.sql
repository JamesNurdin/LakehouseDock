WITH store_agg AS (
   SELECT
      ss_item_sk,
      ss_cdemo_sk,
      SUM(ss_ext_sales_price) AS store_sales_total,
      SUM(ss_quantity) AS store_quantity_total,
      COUNT(*) AS store_txn_count
   FROM store_sales
   WHERE ss_quantity > 0
     AND ss_ext_sales_price > 0
   GROUP BY ss_item_sk, ss_cdemo_sk
)
SELECT
   i.i_manufact,
   sm.sm_code,
   cd_store.cd_gender AS store_customer_gender,
   cd_bill.cd_gender AS bill_customer_gender,
   SUM(sa.store_sales_total) AS total_store_sales,
   SUM(ws.ws_ext_sales_price) AS total_web_sales,
   SUM(sa.store_sales_total + ws.ws_ext_sales_price) AS total_combined_sales,
   COUNT(DISTINCT sa.store_txn_count) AS store_txn_groups,
   COUNT(DISTINCT ws.ws_order_number) AS web_orders
FROM store_agg sa
JOIN item i
  ON sa.ss_item_sk = i.i_item_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd_store
  ON sa.ss_cdemo_sk = cd_store.cd_demo_sk
JOIN customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
WHERE
   i.i_wholesale_cost > 1.0
   AND i.i_manufact = 'esen stable'
   AND sm.sm_code = 'AIR'
   AND cd_store.cd_gender = 'M'
   AND ws.ws_net_paid_inc_tax > 1000
GROUP BY i.i_manufact, sm.sm_code, cd_store.cd_gender, cd_bill.cd_gender
HAVING SUM(sa.store_sales_total) > 5000
ORDER BY total_combined_sales DESC
LIMIT 100
