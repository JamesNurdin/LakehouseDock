WITH returns_with_details AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_net_loss,
        wr.wr_return_amt,
        d.d_date,
        r.r_reason_desc,
        c.c_email_address AS email_address,
        wp.wp_url AS page_url
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
)
SELECT
    email_domain,
    CONCAT('Domain: ', email_domain) AS domain_label,
    COUNT(*) AS num_returns,
    SUM(wr_net_loss) AS total_net_loss,
    SUM(wr_return_amt) AS total_return_amt,
    MIN(d_date) AS first_return_date,
    MAX(d_date) AS last_return_date,
    ARRAY_AGG(DISTINCT page_domain) AS page_domains
FROM (
    SELECT
        wr_returned_date_sk,
        wr_net_loss,
        wr_return_amt,
        d_date,
        r_reason_desc,
        regexp_extract(email_address, '@([^.]*)\\.', 1) AS email_domain,
        regexp_extract(page_url, 'https?://([^/]+)/', 1) AS page_domain
    FROM returns_with_details
) t
WHERE REGEXP_LIKE(r_reason_desc, '(?i)defect')
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_name LIKE '%Holiday%'
          AND t.wr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    )
GROUP BY email_domain, CONCAT('Domain: ', email_domain)
HAVING SUM(wr_net_loss) > (
    SELECT AVG(wr2.wr_net_loss)
    FROM web_returns wr2
)
ORDER BY total_net_loss DESC
LIMIT 100
