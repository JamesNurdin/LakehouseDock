WITH sampled_cs AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_ext_sales_price > 0
)
SELECT
    p.p_promo_name,
    sm.sm_carrier,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(DISTINCT cs.cs_ext_sales_price) AS distinct_sales,
    AVG(cs.cs_quantity) AS avg_quantity,
    REGEXP_EXTRACT(p.p_promo_name, '(\\w+)\\s+Promo') AS promo_type,
    CASE
        WHEN SUBSTRING(sm.sm_carrier, 1, 3) = 'AIR' THEN 'Air'
        ELSE 'Other'
    END AS carrier_group
FROM sampled_cs cs
JOIN promotion p        ON cs.cs_promo_sk      = p.p_promo_sk
JOIN ship_mode sm       ON cs.cs_ship_mode_sk  = sm.sm_ship_mode_sk
JOIN catalog_page cp    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
    REGEXP_LIKE(p.p_promo_name, '^.*Promo$')
    AND cp.cp_description LIKE '%Holiday%'
GROUP BY
    p.p_promo_name,
    sm.sm_carrier,
    REGEXP_EXTRACT(p.p_promo_name, '(\\w+)\\s+Promo'),
    CASE
        WHEN SUBSTRING(sm.sm_carrier, 1, 3) = 'AIR' THEN 'Air'
        ELSE 'Other'
    END
ORDER BY distinct_sales DESC
LIMIT 20
