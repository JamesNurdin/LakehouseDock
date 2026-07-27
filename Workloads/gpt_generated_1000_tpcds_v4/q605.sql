WITH store_closure AS (
    SELECT
        s.s_store_sk,
        s.s_division_name,
        d.d_year AS closed_year,
        d.d_date_id
    FROM store s
    JOIN date_dim d
      ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_closed_date_sk IS NOT NULL
),
page_details AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_char_count,
        wp.wp_type,
        d.d_year AS creation_year,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
        CASE WHEN wp.wp_url LIKE '%promo%' THEN 1 ELSE 0 END AS is_promo,
        CONCAT('URL:', wp.wp_url) AS url_label
    FROM web_page wp
    JOIN date_dim d
      ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE wp.wp_url IS NOT NULL
)
SELECT
    sc.s_division_name,
    sc.closed_year,
    COUNT(pd.wp_web_page_sk) AS total_pages,
    SUM(CASE WHEN pd.is_promo = 1 THEN 1 ELSE 0 END) AS promo_pages,
    AVG(pd.wp_char_count) AS avg_char_count,
    ARRAY_AGG(DISTINCT pd.domain) FILTER (WHERE pd.domain IS NOT NULL) AS distinct_domains,
    MAX(pd.url_label) FILTER (WHERE regexp_like(pd.wp_type, '^ad|dynamic$')) AS sample_ad_dynamic_url
FROM store_closure sc
JOIN page_details pd
  ON pd.creation_year = sc.closed_year
WHERE pd.wp_url LIKE '%.com%'
  AND substring(pd.wp_url, 1, 4) = 'http'
  AND regexp_like(pd.wp_type, 'ad|dynamic')
GROUP BY sc.s_division_name, sc.closed_year
ORDER BY total_pages DESC, sc.s_division_name
LIMIT 100
