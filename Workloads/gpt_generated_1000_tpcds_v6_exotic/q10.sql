WITH filtered AS (
    SELECT
        wr.wr_return_amt,
        wp.wp_url,
        d.d_year
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND wp.wp_url LIKE '%/product/%'
      AND regexp_like(wp.wp_url, '^https?://')
)
SELECT
    wp_url,
    substr(wp_url, 1, 20) AS url_prefix,
    regexp_extract(wp_url, 'https?://([^/]+)', 1) AS domain,
    sum(wr_return_amt) AS total_return_amt,
    count(*) AS return_cnt,
    CASE WHEN sum(wr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS return_level
FROM filtered
GROUP BY wp_url, substr(wp_url, 1, 20), regexp_extract(wp_url, 'https?://([^/]+)', 1)
ORDER BY total_return_amt DESC
LIMIT 100
