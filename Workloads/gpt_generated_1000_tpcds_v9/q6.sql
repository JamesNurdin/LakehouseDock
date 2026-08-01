WITH page_returns AS (
    SELECT
        dr.d_year,
        dr.d_date,
        sr.sr_store_sk,
        sr.sr_net_loss,
        wp.wp_url,
        wp.wp_type,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
        substring(wp.wp_url, 9, 5) AS url_part
    FROM store_returns sr
    JOIN date_dim dr
        ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = dr.d_date_sk
    WHERE wp.wp_type LIKE 'ad%'
        AND regexp_like(wp.wp_url, '^https?://.*\\.com')
        AND dr.d_date >= DATE '2022-01-01'
        AND dr.d_date < DATE '2023-01-01'
)
SELECT
    d_year,
    domain,
    COUNT(DISTINCT sr_store_sk) AS stores_with_returns,
    SUM(sr_net_loss) AS total_net_loss,
    CONCAT('Domain: ', domain) AS domain_label,
    MIN(url_part) AS sample_url_part
FROM page_returns
GROUP BY d_year, domain
HAVING SUM(sr_net_loss) > 0
ORDER BY total_net_loss DESC, d_year
LIMIT 100
