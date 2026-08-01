WITH sales_agg AS (
   SELECT
      w.w_state,
      i.i_category,
      p.p_promo_name,
      SUM(cs.cs_net_paid) AS total_sales,
      COUNT(DISTINCT cs.cs_order_number) AS order_cnt
   FROM tpcds.catalog_sales cs
   JOIN tpcds.warehouse w   ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN tpcds.item i       ON cs.cs_item_sk = i.i_item_sk
   JOIN tpcds.promotion p  ON cs.cs_promo_sk = p.p_promo_sk
   WHERE w.w_state IN ('TN', 'GA')
     AND p.p_discount_active = 'N'
     AND NOT EXISTS (
           SELECT 1
           FROM tpcds.inventory inv
           WHERE inv.inv_item_sk = i.i_item_sk
        )
   GROUP BY CUBE (w.w_state, i.i_category, p.p_promo_name)
),

sales_agg2 AS (
   SELECT
      w.w_state,
      i.i_category,
      p.p_promo_name,
      SUM(cs.cs_net_paid) AS total_sales,
      COUNT(DISTINCT cs.cs_order_number) AS order_cnt
   FROM tpcds.catalog_sales cs
   JOIN tpcds.warehouse w   ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN tpcds.item i       ON cs.cs_item_sk = i.i_item_sk
   JOIN tpcds.promotion p  ON cs.cs_promo_sk = p.p_promo_sk
   WHERE w.w_state IN ('NM', 'AL')
     AND p.p_start_date_sk > 2450300
     AND NOT EXISTS (
           SELECT 1
           FROM tpcds.inventory inv
           WHERE inv.inv_item_sk = i.i_item_sk
        )
   GROUP BY CUBE (w.w_state, i.i_category, p.p_promo_name)
)

SELECT DISTINCT
   w_state,
   i_category,
   p_promo_name,
   total_sales,
   order_cnt
FROM sales_agg

UNION

SELECT DISTINCT
   w_state,
   i_category,
   p_promo_name,
   total_sales,
   order_cnt
FROM sales_agg2

ORDER BY total_sales DESC
LIMIT 100
