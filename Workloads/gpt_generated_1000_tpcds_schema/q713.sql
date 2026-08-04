WITH sampled_items AS (
    SELECT i_item_sk,
           i_product_name,
           i_category,
           i_current_price
    FROM item TABLESAMPLE BERNOULLI (10)
),
catalog_agg AS (
    SELECT i.i_item_sk           AS item_sk,
           i.i_product_name      AS product_name,
           'catalog'             AS sales_channel,
           SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
           COUNT(*)              AS sales_cnt,
           (
               SELECT MAX(p.p_discount_active)
               FROM promotion p
               WHERE p.p_item_sk = i.i_item_sk
           )                     AS has_active_discount
    FROM catalog_sales cs
    JOIN sampled_items i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    WHERE td.t_meal_time = 'dinner'
    GROUP BY i.i_item_sk, i.i_product_name
),
store_agg AS (
    SELECT i.i_item_sk           AS item_sk,
           i.i_product_name      AS product_name,
           'store'               AS sales_channel,
           SUM(ss.ss_net_paid_inc_tax) AS total_sales,
           COUNT(*)              AS sales_cnt,
           (
               SELECT MAX(p.p_discount_active)
               FROM promotion p
               WHERE p.p_item_sk = i.i_item_sk
           )                     AS has_active_discount
    FROM store_sales ss
    JOIN sampled_items i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE td.t_meal_time = 'dinner'
    GROUP BY i.i_item_sk, i.i_product_name
),
combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
)
SELECT c.item_sk,
       c.product_name,
       c.sales_channel,
       c.total_sales,
       c.sales_cnt,
       g.cd_gender,
       lt.max_price
FROM combined c
CROSS JOIN (
    SELECT DISTINCT cd.cd_gender
    FROM customer_demographics cd
    WHERE cd.cd_gender IS NOT NULL
    LIMIT 5
) g
LEFT JOIN LATERAL (
    SELECT MAX(i2.i_current_price) AS max_price
    FROM sampled_items i2
    WHERE i2.i_item_sk = c.item_sk
) lt ON TRUE
WHERE EXISTS (
    SELECT 1
    FROM promotion p
    WHERE p.p_item_sk = c.item_sk
      AND p.p_discount_active = 'Y'
)
ORDER BY c.total_sales DESC
OFFSET 0
LIMIT 100
