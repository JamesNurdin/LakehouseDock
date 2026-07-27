WITH store_dates AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_zip,
        d.d_date_sk,
        d.d_date,
        d.d_quarter_name,
        d.d_year
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_state = 'CA'
      AND s.s_zip = '32477     '
      AND d.d_quarter_name = '1900Q3'
      AND d.d_year = 2000
      AND d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
)
SELECT
    sd.s_store_sk,
    sd.s_store_name,
    sd.s_state,
    sd.s_zip,
    sd.d_date,
    sd.d_quarter_name,
    COALESCE(wp.wp_url, 'N/A') AS web_page_url,
    wp.wp_max_ad_count,
    CASE
        WHEN wp.wp_max_ad_count >= 3 THEN 'HighAds'
        WHEN wp.wp_max_ad_count = 0 THEN 'NoAds'
        ELSE 'LowAds'
    END AS ad_category,
    ROW_NUMBER() OVER (PARTITION BY sd.s_state ORDER BY sd.d_date DESC) AS rn_state,
    RANK() OVER (ORDER BY wp.wp_max_ad_count DESC NULLS LAST) AS rank_by_ads
FROM store_dates sd
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = sd.d_date_sk
WHERE wp.wp_max_ad_count IS NOT NULL
  AND wp.wp_max_ad_count >= 1
  AND wp.wp_url LIKE 'http://www.%'
  AND wp.wp_type = 'HOME'
  AND wp.wp_rec_end_date >= DATE '1999-01-01'
  AND wp.wp_autogen_flag = 'N'
ORDER BY rank_by_ads
LIMIT 100
