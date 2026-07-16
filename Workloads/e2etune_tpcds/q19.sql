WITH store_active AS (
    SELECT
        s_store_sk,
        s_state,
        s_city,
        s_floor_space,
        s_tax_percentage,
        s_rec_start_date,
        s_rec_end_date
    FROM store
    WHERE s_country = 'United States'
      AND s_rec_start_date <= DATE '2025-12-31'
      AND (s_rec_end_date IS NULL OR s_rec_end_date >= DATE '2025-01-01')
),
website_active AS (
    SELECT
        web_site_sk,
        web_state,
        web_city,
        web_tax_percentage,
        web_rec_start_date,
        web_rec_end_date
    FROM web_site
    WHERE web_class = 'Retail'
      AND web_rec_start_date <= DATE '2025-12-31'
      AND (web_rec_end_date IS NULL OR web_rec_end_date >= DATE '2025-01-01')
)
SELECT
    sa.s_state AS state,
    COUNT(DISTINCT sa.s_store_sk) AS store_cnt,
    COUNT(DISTINCT wa.web_site_sk) AS website_cnt,
    AVG(sa.s_floor_space) AS avg_floor_space,
    AVG(sa.s_tax_percentage) AS avg_store_tax_pct,
    AVG(wa.web_tax_percentage) AS avg_website_tax_pct,
    (AVG(wa.web_tax_percentage) - AVG(sa.s_tax_percentage)) AS tax_pct_diff
FROM store_active sa
JOIN website_active wa
    ON sa.s_state = wa.web_state
GROUP BY sa.s_state
HAVING COUNT(DISTINCT sa.s_store_sk) >= 5
ORDER BY store_cnt DESC
LIMIT 20
