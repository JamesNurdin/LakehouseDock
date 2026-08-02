WITH warehouse_filtered AS (
    SELECT
        w_warehouse_sk,
        w_city,
        w_state,
        w_street_name,
        w_street_type,
        CONCAT(w_city, ', ', w_state) AS city_state,
        regexp_extract(w_city, '(Pleasant|Riverside|Pine)', 1) AS city_match,
        substring(w_city, 1, 3) AS city_prefix_3
    FROM warehouse
    WHERE regexp_like(w_city, '^Pleasant')
      AND w_street_name LIKE '%Sunset%'
),
high_risk_high_estimate_customers AS (
    SELECT cd_demo_sk FROM customer_demographics WHERE cd_credit_rating LIKE '%Risk%'
    INTERSECT
    SELECT cd_demo_sk FROM customer_demographics WHERE cd_purchase_estimate > 5000
)
SELECT
    COALESCE(wf.w_city, 'All Cities') AS city,
    cd.cd_credit_rating,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    CASE
        WHEN cd.cd_credit_rating = 'High Risk' THEN 'High'
        WHEN cd.cd_credit_rating = 'Low Risk' THEN 'Low'
        ELSE 'Other'
    END AS risk_category,
    CASE
        WHEN SUM(cr.cr_net_loss) > (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) THEN 'AboveAvg'
        ELSE 'BelowAvg'
    END AS loss_level,
    MAX(wf.city_state) AS city_state,
    MAX(wf.city_match) AS city_match,
    MAX(wf.city_prefix_3) AS city_prefix_3
FROM catalog_returns cr
RIGHT OUTER JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
LEFT JOIN warehouse_filtered wf
    ON cr.cr_warehouse_sk = wf.w_warehouse_sk
WHERE cd.cd_demo_sk IN (SELECT cd_demo_sk FROM high_risk_high_estimate_customers)
GROUP BY CUBE(wf.w_city, cd.cd_credit_rating)
ORDER BY city, cd.cd_credit_rating
LIMIT 100
