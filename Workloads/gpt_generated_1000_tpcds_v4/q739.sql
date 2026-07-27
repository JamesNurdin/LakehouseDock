WITH catalog_agg AS (
   SELECT
       cs_item_sk,
       cs_call_center_sk,
       SUM(cs_ext_sales_price) AS cat_sales,
       SUM(cs_ext_discount_amt) AS cat_discount,
       SUM(cs_coupon_amt) AS cat_coupon
   FROM catalog_sales
   WHERE cs_coupon_amt > 500
     AND cs_ext_list_price BETWEEN 2000 AND 12000
     AND cs_ship_cdemo_sk IN (2560, 307069)
   GROUP BY cs_item_sk, cs_call_center_sk
),
store_agg AS (
   SELECT
       ss_item_sk,
       SUM(ss_ext_sales_price) AS store_sales,
       SUM(ss_ext_discount_amt) AS store_discount,
       SUM(ss_quantity) AS total_quantity,
       SUM(ss_net_profit) AS total_profit
   FROM store_sales
   WHERE ss_quantity > 1
     AND ss_net_profit > 0
   GROUP BY ss_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_manager_id,
    i.i_size,
    i.i_manufact,
    cc.cc_name,
    ca.cat_sales,
    sa.store_sales,
    (COALESCE(ca.cat_sales, 0) + COALESCE(sa.store_sales, 0)) AS total_sales,
    RANK() OVER (PARTITION BY i.i_manufact ORDER BY (COALESCE(ca.cat_sales, 0) + COALESCE(sa.store_sales, 0)) DESC) AS manuf_sales_rank
FROM store_agg sa
JOIN catalog_agg ca ON sa.ss_item_sk = ca.cs_item_sk
JOIN item i ON i.i_item_sk = sa.ss_item_sk
JOIN call_center cc ON ca.cs_call_center_sk = cc.cc_call_center_sk
WHERE i.i_manager_id IN (63, 19)
  AND i.i_size = 'economy'
  AND i.i_manufact = 'eseoughtable'
  AND cc.cc_mkt_desc LIKE '%Common%'
  AND cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
ORDER BY total_sales DESC
LIMIT 100
