WITH base AS (
   SELECT
       cs.cs_order_number,
       cs.cs_net_profit,
       c.c_customer_id,
       cd.cd_gender,
       p.p_promo_name,
       p.p_discount_active,
       sm.sm_type,
       i.i_item_id,
       i2.i_item_id AS cr_item_id,
       cc.cc_name,
       cp.cp_department,
       w.w_warehouse_name,
       t_sold.t_meal_time,
       sr.sr_return_quantity,
       s.s_store_name
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
   LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   LEFT JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
   LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
   LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
),
intersect_keys AS (
   SELECT DISTINCT c_customer_id, cd_gender, p_promo_name
   FROM base
   WHERE p_discount_active = 'Y'
   INTERSECT
   SELECT DISTINCT c_customer_id, cd_gender, p_promo_name
   FROM base
   WHERE sr_return_quantity > 0
)
SELECT
    ik.c_customer_id,
    ik.cd_gender,
    ik.p_promo_name,
    ROW_NUMBER() OVER (ORDER BY ik.c_customer_id) AS row_num
FROM intersect_keys ik
ORDER BY row_num
LIMIT 100
