WITH filtered_pages AS (
    SELECT
        wp_customer_sk,
        wp_web_page_id,
        wp_url,
        regexp_extract(wp_url, 'https?://([^/]+)', 1) AS domain,
        wp_type
    FROM web_page
    WHERE wp_autogen_flag = 'N'
      AND regexp_like(wp_url, '^https?://.*\\.com')
)
SELECT
    concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    c.c_last_name,
    substring(c.c_email_address, 1, 10) AS email_prefix,
    fp.domain,
    fp.wp_type,
    COUNT(ss.ss_ticket_number) AS order_count,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_net_paid) AS avg_net_paid
FROM filtered_pages fp
JOIN customer c
    ON fp.wp_customer_sk = c.c_customer_sk
JOIN store_sales ss
    ON ss.ss_customer_sk = c.c_customer_sk
WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@[^@]+\\.com$')
  AND c.c_last_review_date BETWEEN 2452500 AND 2452600
  AND ss.ss_coupon_amt > 200
GROUP BY
    concat(c.c_first_name, ' ', c.c_last_name),
    c.c_last_name,
    substring(c.c_email_address, 1, 10),
    fp.domain,
    fp.wp_type
ORDER BY total_net_paid DESC
LIMIT 100
