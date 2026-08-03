WITH catalog_sales_base AS (
       SELECT
         d.d_date AS sale_date,
         i.i_item_id,
         i.i_product_name,
         cs.cs_quantity AS quantity,
         cs.cs_net_paid AS net_paid,
         p.p_promo_name,
         split(p.p_channel_details, ',') AS channels
       FROM catalog_sales cs
       JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
       JOIN item i ON cs.cs_item_sk = i.i_item_sk
       JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
       WHERE d.d_year = 2000
     ),
     catalog_expanded AS (
       SELECT
         c.sale_date,
         c.i_item_id,
         c.i_product_name,
         c.quantity,
         c.net_paid,
         c.p_promo_name,
         trim(ch) AS channel
       FROM catalog_sales_base c
       CROSS JOIN UNNEST(c.channels) AS t(ch)
     ),
     store_sales_base AS (
       SELECT
         d.d_date AS sale_date,
         i.i_item_id,
         i.i_product_name,
         ss.ss_quantity AS quantity,
         ss.ss_net_paid AS net_paid,
         p.p_promo_name,
         split(p.p_channel_details, ',') AS channels
       FROM store_sales ss
       JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
       JOIN item i ON ss.ss_item_sk = i.i_item_sk
       JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
       WHERE d.d_year = 2000
     ),
     store_expanded AS (
       SELECT
         s.sale_date,
         s.i_item_id,
         s.i_product_name,
         s.quantity,
         s.net_paid,
         s.p_promo_name,
         trim(ch) AS channel
       FROM store_sales_base s
       CROSS JOIN UNNEST(s.channels) AS t(ch)
     ),
     combined AS (
       SELECT 'catalog' AS sale_type,
              sale_date,
              i_item_id,
              i_product_name,
              quantity,
              net_paid,
              p_promo_name,
              channel
       FROM catalog_expanded
       UNION ALL
       SELECT 'store' AS sale_type,
              sale_date,
              i_item_id,
              i_product_name,
              quantity,
              net_paid,
              p_promo_name,
              channel
       FROM store_expanded
     ),
     ranked AS (
       SELECT
         sale_type,
         sale_date,
         i_item_id,
         i_product_name,
         quantity,
         net_paid,
         p_promo_name,
         channel,
         ROW_NUMBER() OVER (PARTITION BY date_trunc('month', sale_date), channel ORDER BY net_paid DESC) AS rn,
         CASE WHEN net_paid > 1000 THEN 'high' ELSE 'normal' END AS revenue_category
       FROM combined
     )
SELECT
  sale_type,
  sale_date,
  i_item_id,
  i_product_name,
  quantity,
  net_paid,
  p_promo_name,
  channel,
  revenue_category
FROM ranked
WHERE rn <= 5
ORDER BY sale_date DESC, channel, rn
LIMIT 100
