WITH sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_net_paid_inc_tax,
        ss.ss_item_sk
    FROM store_sales ss
    WHERE ss.ss_net_paid_inc_tax > 0
),
date_join AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_date_sk,
        d.d_date,
        d.d_year,
        ss.ss_net_paid_inc_tax,
        ss.ss_item_sk
    FROM sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
),
catalog AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_description,
        cp.cp_start_date_sk,
        cp.cp_end_date_sk,
        cp.cp_catalog_number
    FROM catalog_page cp
    WHERE regexp_like(cp.cp_description, '(?i)promo|sale')
),
web AS (
    SELECT
        wp.wp_url,
        wp.wp_creation_date_sk,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain
    FROM web_page wp
    WHERE wp.wp_url LIKE 'http%://%.com/%'
      AND regexp_like(wp.wp_url, '\\.html$')
)
SELECT
    dj.s_store_name,
    c.cp_catalog_page_id,
    SUM(dj.ss_net_paid_inc_tax) AS total_sales,
    COUNT(DISTINCT w.domain) AS distinct_domains,
    CONCAT('Store-', CAST(dj.s_store_sk AS VARCHAR)) AS store_key
FROM date_join dj
JOIN catalog c
  ON dj.d_date_sk = c.cp_start_date_sk OR dj.d_date_sk = c.cp_end_date_sk
LEFT JOIN web w
  ON dj.d_date_sk = w.wp_creation_date_sk
GROUP BY
    dj.s_store_name,
    c.cp_catalog_page_id,
    dj.s_store_sk
ORDER BY total_sales DESC
LIMIT 20
