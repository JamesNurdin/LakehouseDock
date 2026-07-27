WITH joined AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        wp.wp_max_ad_count,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
        substr(wp.wp_type, 1, 5) AS type_prefix
    FROM web_page wp
    JOIN web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_url LIKE 'http://www.%'
      AND regexp_like(wp.wp_url, '^https?://[^/]+\\.com')
),
aggregated AS (
    SELECT
        domain,
        type_prefix,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_return_quantity) AS avg_quantity,
        CONCAT('Domain: ', domain) AS label
    FROM joined
    GROUP BY domain, type_prefix
    HAVING SUM(wr_return_amt) > 1000
)
SELECT
    domain,
    type_prefix,
    return_cnt,
    total_return_amt,
    avg_quantity,
    label,
    ROW_NUMBER() OVER (PARTITION BY domain ORDER BY total_return_amt DESC) AS rn
FROM aggregated
ORDER BY total_return_amt DESC
LIMIT 20
