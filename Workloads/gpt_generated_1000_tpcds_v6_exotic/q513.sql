WITH per_group AS (
   SELECT
      cp.cp_department,
      sm.sm_type,
      p.p_promo_name,
      td.t_shift,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(*) AS order_cnt
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   WHERE cp.cp_catalog_page_number IN (8, 10, 12)
     AND sm.sm_contract LIKE 'yV%'
     AND td.t_shift = 'first'
   GROUP BY cp.cp_department, sm.sm_type, p.p_promo_name, td.t_shift
),
dept_filter AS (
   SELECT DISTINCT cp_department FROM per_group WHERE total_sales > 20000
   UNION
   SELECT DISTINCT cp_department FROM per_group WHERE total_profit > 5000
)
SELECT
   pg.cp_department,
   pg.sm_type,
   pg.p_promo_name,
   pg.t_shift,
   pg.total_sales,
   pg.total_profit,
   pg.order_cnt,
   pg.avg_sales_overall
FROM (
   SELECT
      pg.*,
      (SELECT AVG(total_sales) FROM per_group) AS avg_sales_overall
   FROM per_group pg
   WHERE pg.cp_department IN (SELECT cp_department FROM dept_filter)
     AND NOT EXISTS (
         SELECT 1 FROM promotion p2
         WHERE p2.p_promo_name = pg.p_promo_name
           AND p2.p_discount_active = 'Y'
     )
) pg
ORDER BY pg.total_sales DESC
LIMIT 100
