WITH demo_agg AS (
    SELECT
        cd_education_status,
        cd_marital_status,
        COUNT(*) AS demo_cnt,
        AVG(cd_purchase_estimate) AS avg_purchase,
        SUM(cd_dep_employed_count) AS total_employed_deps
    FROM customer_demographics
    WHERE cd_purchase_estimate >= 1500
    GROUP BY cd_education_status, cd_marital_status
),
site_agg AS (
    SELECT
        web_state,
        web_country,
        COUNT(*) AS site_cnt,
        AVG(web_tax_percentage) AS avg_tax,
        SUM(CASE WHEN web_gmt_offset > 0 THEN 1 ELSE 0 END) AS pos_gmt_sites
    FROM web_site
    WHERE web_gmt_offset BETWEEN -5.00 AND 5.00
    GROUP BY web_state, web_country
)
SELECT
    d.cd_education_status,
    d.cd_marital_status,
    s.web_state,
    s.web_country,
    d.demo_cnt,
    s.site_cnt,
    d.avg_purchase,
    s.avg_tax,
    (d.demo_cnt * s.site_cnt) AS combined_metric,
    RANK() OVER (PARTITION BY d.cd_education_status ORDER BY (d.demo_cnt * s.site_cnt) DESC) AS rank_within_education
FROM demo_agg d
JOIN site_agg s ON 1 = 1
WHERE d.demo_cnt > 5
  AND s.site_cnt > 3
ORDER BY rank_within_education
LIMIT 50
