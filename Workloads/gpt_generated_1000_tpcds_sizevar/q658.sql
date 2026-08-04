WITH small_modes AS (
   SELECT sm.sm_ship_mode_id
   FROM ship_mode sm
   LIMIT 5
),
union_sales AS (
   SELECT i.i_category AS category,
          sm.sm_ship_mode_id AS ship_mode,
          'ItemSales' AS source,
          SUM(cs.cs_ext_sales_price) AS total_amount
   FROM catalog_sales cs
   RIGHT OUTER JOIN warehouse w
       ON cs.cs_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN item i
       ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE (cs.cs_sold_date_sk IS NULL OR cs.cs_sold_date_sk BETWEEN 2450815 AND 2451170)
   GROUP BY i.i_category, sm.sm_ship_mode_id

   UNION

   SELECT i.i_category AS category,
          sm.sm_ship_mode_id AS ship_mode,
          'PromoSales' AS source,
          SUM(cs.cs_ext_sales_price) AS total_amount
   FROM promotion p
   JOIN item i
       ON p.p_item_sk = i.i_item_sk
   JOIN catalog_sales cs
       ON cs.cs_promo_sk = p.p_promo_sk
   CROSS JOIN small_modes sm
   WHERE p.p_discount_active = 'Y'
   GROUP BY i.i_category, sm.sm_ship_mode_id
)
SELECT
   category,
   ship_mode,
   source,
   total_amount,
   ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_amount DESC) AS rn
FROM union_sales
ORDER BY category, rn
