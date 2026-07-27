/* goal: Compare total net paid (including shipping) for promotions under two different ship mode categories, filtering by above‑average sales and additional promotion/ship‑mode criteria. The result shows distinct promotion‑ship mode pairs with their aggregated net paid, combined via UNION ALL. */
WITH avg_net AS (
    SELECT AVG(cs_net_paid_inc_ship) AS avg_val
    FROM tpcds.catalog_sales
)
,
promo_air AS (
    SELECT DISTINCT
        p.p_promo_id,
        sm.sm_ship_mode_id,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        'AIR' AS ship_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE p.p_purpose = 'Unknown'
      AND sm.sm_code = 'AIR'
      AND cs.cs_net_paid_inc_ship > (SELECT avg_val FROM avg_net)
      AND EXISTS (
          SELECT 1
          FROM tpcds.ship_mode sm2
          WHERE sm2.sm_ship_mode_sk = cs.cs_ship_mode_sk
            AND sm2.sm_contract = 'Ek'
      )
    GROUP BY p.p_promo_id, sm.sm_ship_mode_id
)
,
promo_sea AS (
    SELECT DISTINCT
        p.p_promo_id,
        sm.sm_ship_mode_id,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        'SEA' AS ship_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE p.p_purpose <> 'Unknown'
      AND sm.sm_code = 'SEA'
      AND cs.cs_net_paid_inc_ship > (SELECT avg_val FROM avg_net)
      AND p.p_promo_sk IN (
          SELECT cs2.cs_promo_sk
          FROM tpcds.catalog_sales cs2
          WHERE cs2.cs_quantity > 5
      )
    GROUP BY p.p_promo_id, sm.sm_ship_mode_id
)
SELECT
    a.p_promo_id,
    a.sm_ship_mode_id,
    a.total_net_paid,
    a.ship_category
FROM promo_air a
UNION ALL
SELECT
    b.p_promo_id,
    b.sm_ship_mode_id,
    b.total_net_paid,
    b.ship_category
FROM promo_sea b
LIMIT 100
