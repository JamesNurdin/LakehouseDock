WITH filtered_web AS (
    SELECT
        wp_web_page_sk,
        wp_url,
        wp_creation_date_sk,
        regexp_extract(wp_url, 'https?://([^/]+)/', 1) AS domain,
        CASE
            WHEN regexp_like(wp_url, '\\.example\\.com') THEN 'example'
            ELSE 'other'
        END AS url_group
    FROM web_page
    WHERE wp_url LIKE 'http%'
      AND regexp_like(wp_url, '\\.example\\.com')
)
SELECT
    ca.ca_state,
    ca.ca_city,
    CONCAT(ca.ca_state, '-', ca.ca_city) AS state_city,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    RANK() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank,
    (
        SELECT COUNT(*)
        FROM catalog_page cp
        WHERE cp.cp_start_date_sk = d.d_date_sk
    ) AS catalog_pages_on_date
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE EXISTS (
    SELECT 1
    FROM filtered_web fw
    WHERE fw.wp_creation_date_sk = d.d_date_sk
)
  AND ca.ca_location_type LIKE '%family%'
  AND regexp_like(ca.ca_city, '^[A-M].*')
GROUP BY ca.ca_state, ca.ca_city, d.d_date_sk
ORDER BY total_profit DESC
LIMIT 100
