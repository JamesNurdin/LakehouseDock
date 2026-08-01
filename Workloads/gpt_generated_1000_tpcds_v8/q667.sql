/*
  goal: Identify item SKs that were sold in a specific quarter with high sales price and active promotions, also belong to a low‑risk credit customer segment, but exclude items belonging to the Electronics category that were sold in large quantities. The result is de‑duplicated, filtered for items that currently have at least one promotion, ordered, paginated and limited to 100 rows.
*/
WITH intersect_set AS (
    SELECT ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_quarter_name = '1902Q3'
      AND ss.ss_ext_sales_price > 1000
      AND p.p_discount_active = 'Y'
    GROUP BY ss.ss_item_sk
),
union_set AS (
    SELECT ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Low Risk'
      AND cd.cd_purchase_estimate >= 3500
    GROUP BY ss.ss_item_sk
),
except_set AS (
    SELECT ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
      AND ss.ss_quantity > 5
    GROUP BY ss.ss_item_sk
),
combined AS (
    SELECT item_sk FROM intersect_set
    INTERSECT
    SELECT item_sk FROM union_set
),
filtered AS (
    SELECT item_sk FROM combined
    EXCEPT
    SELECT item_sk FROM except_set
)
SELECT DISTINCT f.item_sk
FROM filtered f
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS promo_cnt
    FROM promotion p
    WHERE p.p_item_sk = f.item_sk
) pc
WHERE pc.promo_cnt > 0
ORDER BY f.item_sk
OFFSET 20 LIMIT 100
