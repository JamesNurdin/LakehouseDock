WITH sub_a AS (
    SELECT DISTINCT
        cp.cp_catalog_page_id AS cp_catalog_page_id,
        p.p_promo_id AS p_promo_id
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND d.d_moy = 12
      AND sm.sm_carrier = 'AIRBORNE'
      AND hd.hd_income_band_sk > 8
      AND cs.cs_net_profit > 1000
),
sub_b AS (
    SELECT DISTINCT
        cp.cp_catalog_page_id AS cp_catalog_page_id,
        p.p_promo_id AS p_promo_id
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND d.d_moy = 12
      AND sm.sm_code = 'AIR'
      AND hd.hd_vehicle_count >= 2
      AND cs.cs_net_profit > 1500
)
SELECT cp_catalog_page_id, p_promo_id
FROM sub_a
INTERSECT
SELECT cp_catalog_page_id, p_promo_id
FROM sub_b
ORDER BY cp_catalog_page_id, p_promo_id
LIMIT 100
