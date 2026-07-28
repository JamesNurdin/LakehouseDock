WITH sales AS (
    SELECT s.s_store_id,
           s.s_store_name,
           'sale' AS activity_type,
           SUM(ss.ss_net_paid) AS total_amount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE i.i_category_id = 5
      AND p.p_discount_active = 'Y'
    GROUP BY s.s_store_id, s.s_store_name
),
returns AS (
    SELECT s.s_store_id,
           s.s_store_name,
           'return' AS activity_type,
           SUM(sr.sr_net_loss) AS total_amount
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_category_id = 5
      AND sr.sr_return_quantity > 0
    GROUP BY s.s_store_id, s.s_store_name
)
SELECT s_store_id,
       s_store_name,
       activity_type,
       total_amount
FROM sales
UNION ALL
SELECT s_store_id,
       s_store_name,
       activity_type,
       total_amount
FROM returns
ORDER BY s_store_id, activity_type
