WITH promo_ship AS (
    SELECT
        p.p_promo_name,
        sm.sm_type,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        CASE
            WHEN cs.cs_net_paid > 1000 THEN 'HIGH'
            WHEN cs.cs_net_paid > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '(?i)sale|clearance')
      AND sm.sm_type LIKE 'EXPRESS%'
)
SELECT
    promo_ship.p_promo_name,
    promo_ship.sm_type,
    CONCAT(promo_ship.p_promo_name, ' - ', promo_ship.sm_type) AS promo_mode,
    SUM(promo_ship.cs_quantity) AS total_quantity,
    SUM(promo_ship.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT promo_ship.cs_sold_date_sk) AS distinct_sale_days,
    CASE
        WHEN SUM(promo_ship.cs_net_paid) > 50000 THEN 'BIG'
        ELSE 'SMALL'
    END AS revenue_bucket,
    REGEXP_EXTRACT(promo_ship.p_promo_name, '(?i)(sale|clearance)') AS promo_keyword
FROM promo_ship
GROUP BY ROLLUP(promo_ship.p_promo_name, promo_ship.sm_type)
ORDER BY total_net_paid DESC
LIMIT 100
