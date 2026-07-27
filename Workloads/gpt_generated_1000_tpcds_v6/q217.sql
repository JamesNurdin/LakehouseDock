WITH returns_with_details AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_net_loss,
        d.d_dow,
        wp.wp_url,
        wp.wp_type,
        wp.wp_web_page_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_dow IN (6, 7) -- weekend days (Saturday, Sunday)
      AND regexp_like(wp.wp_url, '\\.(com|org|net)')
      AND wp.wp_type LIKE 'product%'
)
SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    CASE WHEN s.s_number_employees > 250 THEN 'Large' ELSE 'Medium' END AS store_size_category,
    regexp_extract(rw.wp_url, 'https?://([^/]+)/', 1) AS domain,
    COUNT(*) AS return_count,
    SUM(rw.wr_net_loss) AS total_net_loss,
    AVG(rw.wr_net_loss) AS avg_net_loss
FROM returns_with_details rw
JOIN store s ON s.s_closed_date_sk = rw.wr_returned_date_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    CASE WHEN s.s_number_employees > 250 THEN 'Large' ELSE 'Medium' END,
    regexp_extract(rw.wp_url, 'https?://([^/]+)/', 1)
HAVING SUM(rw.wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
