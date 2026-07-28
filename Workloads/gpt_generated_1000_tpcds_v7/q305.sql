WITH filtered_pages AS (
    SELECT
        wp_web_page_sk,
        wp_url,
        regexp_extract(wp_url, 'https?://([^/]+)/', 1) AS domain,
        CASE
            WHEN regexp_like(wp_url, '/electronics/') THEN 'Electronics'
            WHEN regexp_like(wp_url, '/clothing/') THEN 'Clothing'
            ELSE 'Other'
        END AS category
    FROM web_page
    WHERE wp_url LIKE 'http://%' OR wp_url LIKE 'https://%'
)
SELECT
    fp.domain,
    fp.category,
    d.d_year,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM web_returns wr
JOIN filtered_pages fp ON wr.wr_web_page_sk = fp.wp_web_page_sk
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
WHERE d.d_year BETWEEN 2000 AND 2002
  AND fp.category <> 'Other'
GROUP BY fp.domain, fp.category, d.d_year
ORDER BY d.d_year DESC, total_net_loss DESC
LIMIT 100
