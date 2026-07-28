WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_reason_sk,
        r.r_reason_desc,
        r.r_reason_id,
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        regexp_extract(r.r_reason_desc, '^([^ ]+)', 1) AS reason_first_word,
        CASE WHEN regexp_like(r.r_reason_desc, '(?i)product') THEN 1 ELSE 0 END AS contains_product
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE r.r_reason_desc LIKE '%size%'
      AND ca.ca_city LIKE 'M%'
)
SELECT
    reason_first_word,
    COUNT(*) AS return_cnt,
    SUM(cr_return_quantity) AS total_quantity,
    SUM(cr_return_amount) AS total_amount,
    SUM(contains_product) AS product_related_cnt,
    COUNT(DISTINCT c_customer_id) AS distinct_customers
FROM filtered_returns
GROUP BY reason_first_word
HAVING COUNT(*) >= 10
ORDER BY total_amount DESC
LIMIT 100
