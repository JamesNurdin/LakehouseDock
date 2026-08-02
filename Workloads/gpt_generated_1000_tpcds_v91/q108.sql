WITH page_customer AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_web_page_id,
        wp.wp_url,
        wp.wp_type,
        c.c_customer_sk,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        c.c_last_review_date
    FROM web_page wp
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE regexp_like(wp.wp_url, '^https?://.+/product/[0-9]+\\.html$')
      AND wp.wp_type LIKE 'A%'
)
SELECT
    pc.wp_web_page_id,
    pc.wp_url,
    pc.wp_type,
    regexp_extract(pc.wp_url, 'product/([0-9]+)', 1) AS product_id,
    pc.c_customer_id,
    pc.c_customer_id || '_' || pc.wp_type AS cust_page_key,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    COUNT(DISTINCT pc.c_customer_id) AS distinct_customer_cnt,
    (
        SELECT SUM(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = pc.c_customer_sk
    ) AS total_return_amt_for_customer
FROM page_customer pc
JOIN store_returns sr
    ON sr.sr_customer_sk = pc.c_customer_sk
WHERE sr.sr_refunded_cash > 0.0
GROUP BY
    pc.wp_web_page_id,
    pc.wp_url,
    pc.wp_type,
    regexp_extract(pc.wp_url, 'product/([0-9]+)', 1),
    pc.c_customer_id,
    pc.c_customer_id || '_' || pc.wp_type,
    pc.c_customer_sk
ORDER BY total_refunded_cash DESC
