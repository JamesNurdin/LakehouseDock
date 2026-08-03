WITH active_promos AS (
    SELECT
        i.i_brand AS brand,
        i.i_category AS category,
        'Active' AS discount_status,
        SUM(p.p_cost) AS total_promo_cost,
        COUNT(*) AS promo_cnt
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_purpose = 'Clearance'
      )
    GROUP BY CUBE (i.i_brand, i.i_category)
),
inactive_promos AS (
    SELECT
        i.i_brand AS brand,
        i.i_category AS category,
        'Inactive' AS discount_status,
        SUM(p.p_cost) AS total_promo_cost,
        COUNT(*) AS promo_cnt
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active <> 'Y'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_purpose = 'Clearance'
      )
    GROUP BY CUBE (i.i_brand, i.i_category)
)
SELECT
    brand,
    category,
    discount_status,
    total_promo_cost,
    promo_cnt,
    rn
FROM (
    SELECT
        brand,
        category,
        discount_status,
        total_promo_cost,
        promo_cnt,
        ROW_NUMBER() OVER (PARTITION BY brand, category ORDER BY total_promo_cost DESC) AS rn
    FROM (
        SELECT brand, category, discount_status, total_promo_cost, promo_cnt
        FROM active_promos
        UNION ALL
        SELECT brand, category, discount_status, total_promo_cost, promo_cnt
        FROM inactive_promos
    ) u
) t
WHERE rn <= 5
ORDER BY brand ASC, category ASC, total_promo_cost DESC
LIMIT 100
