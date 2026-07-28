WITH promo_filtered AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_cost,
        p.p_promo_name,
        regexp_extract(p.p_promo_id, 'A{5,}([A-Z]+)', 1) AS promo_code_suffix,
        CASE
            WHEN regexp_like(p.p_promo_name, '(?i)sale') THEN 'SALE'
            ELSE 'OTHER'
        END AS promo_category
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '(?i)sale')
      AND p.p_channel_catalog = 'N'
)
SELECT
    ws.web_site_id,
    ws.web_name,
    COUNT(DISTINCT pf.p_promo_sk) AS promo_count,
    AVG(pf.p_cost) AS avg_promo_cost,
    MIN(pf.promo_code_suffix) AS example_suffix
FROM web_site ws
JOIN date_dim d_open
    ON ws.web_open_date_sk = d_open.d_date_sk
JOIN promo_filtered pf
    ON pf.p_start_date_sk = d_open.d_date_sk
WHERE ws.web_name LIKE '%Shop%'
  AND ws.web_country = 'United States'
GROUP BY
    ws.web_site_id,
    ws.web_name
HAVING COUNT(DISTINCT pf.p_promo_sk) > 5
ORDER BY promo_count DESC, ws.web_site_id
LIMIT 100
