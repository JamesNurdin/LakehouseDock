WITH returns_summary AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_customer_sk,
        MIN(sr.sr_reason_sk) AS reason_sk,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_item_sk, sr.sr_customer_sk
)
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    i.i_item_id,
    i.i_product_name,
    r.r_reason_desc,
    rs.total_net_loss,
    rs.return_cnt,
    REGEXP_EXTRACT(r.r_reason_desc, '(because\s+(\w+))', 2) AS reason_keyword,
    CASE WHEN REGEXP_LIKE(c.c_email_address, '@example\\.com$') THEN 1 ELSE 0 END AS is_example_email
FROM returns_summary rs
JOIN customer c ON rs.sr_customer_sk = c.c_customer_sk
JOIN item i ON rs.sr_item_sk = i.i_item_sk
JOIN reason r ON rs.reason_sk = r.r_reason_sk
WHERE i.i_item_desc LIKE '%Premium%'
  AND REGEXP_LIKE(r.r_reason_desc, 'damage|defect')
  AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_url LIKE 'http%://www.%'
    )
ORDER BY rs.total_net_loss DESC
LIMIT 100
