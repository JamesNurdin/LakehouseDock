WITH base AS (
  SELECT
    i.i_category AS category,
    i.i_item_sk,
    hd.hd_demo_sk,
    SUM(ss.ss_ext_sales_price) AS store_sales,
    SUM(cs.cs_ext_sales_price) AS catalog_sales,
    SUM(cr.cr_refunded_cash) AS total_refund,
    SUM(ss.ss_net_paid) AS total_store_net,
    SUM(cs.cs_net_paid) AS total_catalog_net,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_txn_cnt
  FROM store_sales ss
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN catalog_sales cs
    ON i.i_item_sk = cs.cs_item_sk
   AND hd.hd_demo_sk = cs.cs_bill_hdemo_sk
  JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2451910 AND 2451919
    AND ss.ss_quantity > 1
    AND i.i_current_price > 20
    AND hd.hd_dep_count >= 2
    AND ss.ss_net_paid > 0
    AND i.i_brand_id IN (1, 2, 3)
    AND cr.cr_return_amount > 0
    AND cs.cs_quantity > 0
  GROUP BY i.i_category, i.i_item_sk, hd.hd_demo_sk
)
SELECT
  category,
  SUM(store_sales) AS total_store_sales,
  SUM(catalog_sales) AS total_catalog_sales,
  SUM(total_refund) AS total_refunds,
  AVG(total_store_net) AS avg_store_net,
  AVG(total_catalog_net) AS avg_catalog_net,
  SUM(store_sales) / NULLIF(SUM(catalog_sales), 0) AS store_to_catalog_ratio
FROM base
GROUP BY category
HAVING SUM(store_sales) > 50000
ORDER BY total_store_sales DESC
LIMIT 10
