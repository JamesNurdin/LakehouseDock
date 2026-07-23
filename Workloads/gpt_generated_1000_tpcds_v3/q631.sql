WITH filtered_returns AS (
    SELECT
        wr.wr_refunded_customer_sk,
        wr.wr_net_loss,
        wr.wr_returned_date_sk,
        wr.wr_web_page_sk,
        wr.wr_reason_sk
    FROM web_returns wr
    WHERE EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = wr.wr_reason_sk
          AND r.r_reason_desc LIKE '%defect%'
    )
)
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
    SUM(fr.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages_visited,
    MAX(regexp_extract(wp.wp_url, 'category=([^&]+)', 1)) AS most_common_category
FROM filtered_returns fr
JOIN customer c ON fr.wr_refunded_customer_sk = c.c_customer_sk
JOIN web_page wp ON fr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d ON fr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND regexp_like(c.c_email_address, '@gmail\\.com$')
  AND (regexp_like(wp.wp_url, '/product/') OR wp.wp_url LIKE '%/product%')
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, c.c_email_address
ORDER BY total_net_loss DESC
LIMIT 100
