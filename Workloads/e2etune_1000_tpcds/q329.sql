WITH brand_totals AS (
    SELECT i.i_brand,
           SUM(p.p_cost) AS brand_total_cost
    FROM item i
    JOIN promotion p ON i.i_item_sk = p.p_item_sk
    WHERE p.p_discount_active = 'Y'
      AND i.i_rec_end_date > DATE '2000-01-01'
      AND p.p_start_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY i.i_brand
),
brand_category AS (
    SELECT i.i_brand,
           i.i_category,
           SUM(p.p_cost) AS cat_total_cost,
           COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
           AVG(i.i_current_price) AS avg_price
    FROM item i
    JOIN promotion p ON i.i_item_sk = p.p_item_sk
    WHERE p.p_discount_active = 'Y'
      AND i.i_rec_end_date > DATE '2000-01-01'
      AND p.p_start_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY i.i_brand, i.i_category
)
SELECT bc.i_brand,
       bc.i_category,
       bc.cat_total_cost,
       bc.promo_cnt,
       bc.avg_price,
       bt.brand_total_cost,
       RANK() OVER (ORDER BY bc.cat_total_cost DESC) AS cat_rank,
       RANK() OVER (PARTITION BY bc.i_brand ORDER BY bc.cat_total_cost DESC) AS brand_cat_rank,
       RANK() OVER (ORDER BY bt.brand_total_cost DESC) AS brand_rank
FROM brand_category bc
JOIN brand_totals bt ON bc.i_brand = bt.i_brand
WHERE bc.cat_total_cost > 1000
ORDER BY bc.cat_total_cost DESC
LIMIT 20
