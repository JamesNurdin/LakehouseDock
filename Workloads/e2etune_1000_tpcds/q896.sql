WITH customer_returns AS (
    SELECT
        sr.sr_customer_sk,
        COUNT(*) AS num_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY sr.sr_customer_sk
),
customer_pages AS (
    SELECT
        wp.wp_customer_sk,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        MAX(wp.wp_creation_date_sk) AS latest_page_creation_sk
    FROM web_page wp
    WHERE wp.wp_type = 'home'
      AND wp.wp_creation_date_sk >= 2450000
    GROUP BY wp.wp_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.num_returns, 0) AS num_returns,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    COALESCE(cr.avg_return_amt, 0) AS avg_return_amt,
    COALESCE(cp.distinct_pages, 0) AS distinct_pages,
    cp.latest_page_creation_sk
FROM
    customer c
    LEFT JOIN customer_returns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN customer_pages cp ON c.c_customer_sk = cp.wp_customer_sk
WHERE
    c.c_preferred_cust_flag = 'Y'
    AND COALESCE(cr.total_return_amt, 0) > 1000
ORDER BY
    total_return_amt DESC
LIMIT 100
