WITH cust_agg AS (
    SELECT
        c.c_customer_id,
        r.r_reason_desc,
        wp.wp_type,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        wp.wp_char_count BETWEEN 1500 AND 6000                      -- predicate 1
        AND wp.wp_type IN ('Content', 'Product')                     -- predicate 2
        AND r.r_reason_desc LIKE '%damaged%'                         -- predicate 3
        AND wr.wr_return_amt > 10                                    -- predicate 4
        AND c.c_birth_year BETWEEN 1960 AND 1990                     -- predicate 5
    GROUP BY c.c_customer_id, r.r_reason_desc, wp.wp_type
),
distinct_reason_type AS (
    SELECT DISTINCT r_reason_desc, wp_type
    FROM cust_agg
)
SELECT
    drt.r_reason_desc,
    drt.wp_type,
    AVG(ca.total_return_amt) AS avg_return_amt_per_customer,
    SUM(ca.return_cnt) AS total_return_cnt
FROM distinct_reason_type drt
JOIN cust_agg ca
    ON drt.r_reason_desc = ca.r_reason_desc
    AND drt.wp_type = ca.wp_type
GROUP BY drt.r_reason_desc, drt.wp_type
HAVING AVG(ca.total_return_amt) > 100
ORDER BY avg_return_amt_per_customer DESC
