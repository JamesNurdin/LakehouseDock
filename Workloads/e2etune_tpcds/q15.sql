WITH cat_sales_agg AS (
   SELECT
      i.i_item_sk,
      i.i_brand,
      i.i_category,
      p.p_promo_name,
      sm.sm_type AS ship_mode_type,
      w.w_state AS warehouse_state,
      SUM(cs.cs_net_paid_inc_tax) AS cat_sales,
      SUM(cs.cs_net_profit) AS cat_profit,
      SUM(cs.cs_quantity) AS cat_quantity,
      AVG(cs.cs_coupon_amt) AS avg_coupon,
      SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
      COUNT(DISTINCT cs.cs_order_number) AS cat_orders
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE cp.cp_department = 'Electronics'
     AND cp.cp_start_date_sk BETWEEN 2450900 AND 2451000
     AND hd.hd_buy_potential = '500-1000'
   GROUP BY i.i_item_sk, i.i_brand, i.i_category, p.p_promo_name, sm.sm_type, w.w_state
),

store_sales_agg AS (
   SELECT
      i.i_item_sk,
      i.i_brand,
      i.i_category,
      p.p_promo_name,
      SUM(ss.ss_net_paid_inc_tax) AS store_sales,
      SUM(ss.ss_net_profit) AS store_profit,
      SUM(ss.ss_quantity) AS store_quantity,
      AVG(ss.ss_coupon_amt) AS avg_store_coupon,
      COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE hd.hd_buy_potential = '500-1000'
   GROUP BY i.i_item_sk, i.i_brand, i.i_category, p.p_promo_name
)

SELECT
   ca.i_item_sk,
   ca.i_brand,
   ca.i_category,
   ca.p_promo_name,
   ca.ship_mode_type,
   ca.warehouse_state,
   ca.cat_sales,
   ca.cat_profit,
   ca.cat_quantity,
   ca.avg_coupon,
   ca.total_ship_cost,
   ca.cat_orders,
   COALESCE(sa.store_sales, 0) AS store_sales,
   COALESCE(sa.store_profit, 0) AS store_profit,
   COALESCE(sa.store_quantity, 0) AS store_quantity,
   COALESCE(sa.avg_store_coupon, 0) AS avg_store_coupon,
   COALESCE(sa.store_transactions, 0) AS store_transactions,
   (ca.cat_profit + COALESCE(sa.store_profit, 0)) AS total_profit,
   RANK() OVER (ORDER BY (ca.cat_profit + COALESCE(sa.store_profit, 0)) DESC) AS profit_rank
FROM cat_sales_agg ca
FULL OUTER JOIN store_sales_agg sa
   ON ca.i_item_sk = sa.i_item_sk
   AND ca.p_promo_name = sa.p_promo_name
WHERE (ca.cat_sales + COALESCE(sa.store_sales, 0)) > 1000
ORDER BY total_profit DESC
LIMIT 10
