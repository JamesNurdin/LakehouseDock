WITH catalog_ret AS (
        SELECT
            cr.cr_refunded_customer_sk AS customer_sk,
            cr.cr_catalog_page_sk AS catalog_page_sk,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt
        FROM catalog_returns cr
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE REGEXP_LIKE(cp.cp_description, '\\bfunds\\b')
          AND cp.cp_description LIKE '%intense%'
        GROUP BY cr.cr_refunded_customer_sk, cr.cr_catalog_page_sk
    ),
    store_ret AS (
        SELECT
            sr.sr_customer_sk AS customer_sk,
            SUM(sr.sr_return_amt) AS total_store_return,
            COUNT(*) AS store_return_cnt
        FROM store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        WHERE sr.sr_return_quantity > 1
        GROUP BY sr.sr_customer_sk
    ),
    catalog_customers AS (
        SELECT DISTINCT cr_refunded_customer_sk AS customer_sk
        FROM catalog_returns
    ),
    store_customers AS (
        SELECT DISTINCT sr_customer_sk AS customer_sk
        FROM store_returns
    ),
    combined_keys AS (
        SELECT customer_sk FROM catalog_customers
        EXCEPT
        SELECT customer_sk FROM store_customers
        INTERSECT
        SELECT customer_sk FROM store_customers
    )
SELECT
    c.c_customer_id,
    cp.cp_catalog_page_id,
    cr.total_return_amount,
    sr.total_store_return,
    t.first_word,
    SUBSTR(cp.cp_description, 1, 20) AS description_prefix,
    CONCAT(c.c_birth_country, '-', cp.cp_department) AS country_dept
FROM catalog_ret cr
JOIN store_ret sr ON cr.customer_sk = sr.customer_sk
JOIN customer c ON cr.customer_sk = c.c_customer_sk
JOIN catalog_page cp ON cr.catalog_page_sk = cp.cp_catalog_page_sk
JOIN combined_keys ck ON cr.customer_sk = ck.customer_sk
CROSS JOIN LATERAL (
    SELECT REGEXP_EXTRACT(cp.cp_description, '^(\\w+)', 1) AS first_word
) t
ORDER BY cr.total_return_amount DESC
OFFSET 10
LIMIT 100
