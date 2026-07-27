WITH page_returns AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_customer_sk,
        wp.wp_creation_date_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_cnt
    FROM web_page wp
    JOIN web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(wp.wp_url, '^https?://www\\.[a-z]+\\.com')
      AND wp.wp_url LIKE '%foo%'
    GROUP BY wp.wp_web_page_sk, wp.wp_url, wp.wp_customer_sk, wp.wp_creation_date_sk
)
SELECT
    pr.wp_web_page_sk,
    pr.wp_url,
    CONCAT('Domain: ', regexp_extract(pr.wp_url, '^https?://([^/]+)')) AS extracted_domain,
    SUBSTRING(pr.wp_url, 1, 30) AS short_url,
    pr.wp_customer_sk,
    pr.total_return_amt,
    pr.total_refunded_cash,
    pr.return_cnt,
    ROW_NUMBER() OVER (ORDER BY pr.total_return_amt DESC) AS rn
FROM page_returns pr
WHERE pr.wp_customer_sk IN (
    SELECT DISTINCT wr2.wr_returning_customer_sk
    FROM web_returns wr2
    WHERE wr2.wr_return_amt > 100
)
ORDER BY pr.total_return_amt DESC
LIMIT 100
