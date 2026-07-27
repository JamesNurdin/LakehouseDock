WITH combined AS (
   SELECT
       cc.cc_call_center_id,
       i.i_category,
       td.t_hour,
       cs.cs_order_number AS order_number,
       cs.cs_ext_sales_price AS sales_amount,
       cs.cs_net_profit AS profit,
       'SALE' AS txn_type
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE td.t_am_pm = 'AM'
     AND td.t_hour BETWEEN 9 AND 12
     AND cc.cc_market_manager = 'Mark Camp'
     AND i.i_brand = 'BrandA'
     AND p.p_discount_active = 'Y'
     AND cs.cs_quantity > 30
     AND i.i_item_id IN (
         SELECT i2.i_item_id
         FROM item i2
         WHERE i2.i_color = 'Red'
     )
   UNION ALL
   SELECT
       cc.cc_call_center_id,
       i.i_category,
       td.t_hour,
       cr.cr_order_number AS order_number,
       -cr.cr_return_amount AS sales_amount,
       -cr.cr_net_loss AS profit,
       'RETURN' AS txn_type
   FROM catalog_returns cr
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE td.t_am_pm = 'PM'
     AND td.t_hour BETWEEN 13 AND 16
     AND cc.cc_market_manager = 'Mark Camp'
     AND i.i_brand = 'BrandA'
     AND cr.cr_return_quantity > 0
     AND cr.cr_return_amount > 0
),
agg AS (
   SELECT
       cc_call_center_id,
       i_category,
       t_hour,
       COUNT(DISTINCT order_number) AS distinct_orders,
       SUM(sales_amount) AS net_sales,
       SUM(profit) AS net_profit,
       CASE
           WHEN SUM(profit) > 0 THEN 'POSITIVE'
           ELSE 'NON_POSITIVE'
       END AS profit_sign
   FROM combined
   GROUP BY cc_call_center_id, i_category, t_hour
)
SELECT
   cc_call_center_id,
   i_category,
   t_hour,
   distinct_orders,
   net_sales,
   net_profit,
   profit_sign
FROM agg
WHERE net_sales <> 0
ORDER BY net_profit DESC
LIMIT 100
