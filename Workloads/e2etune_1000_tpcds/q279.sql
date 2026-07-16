WITH returns AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        COUNT(*) AS num_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_return_amt) AS avg_return_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2022
      AND t.t_hour BETWEEN 8 AND 18
    GROUP BY c.c_customer_sk, c.c_customer_id
),
pages_created AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT wp.wp_web_page_id) AS pages_created
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_sk
),
pages_accessed AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT wp.wp_web_page_id) AS pages_accessed
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_sk
)
SELECT
    r.c_customer_id,
    r.num_returns,
    r.total_return_amount,
    r.avg_return_amount,
    COALESCE(pc.pages_created, 0) AS pages_created,
    COALESCE(pa.pages_accessed, 0) AS pages_accessed,
    RANK() OVER (ORDER BY r.total_return_amount DESC) AS return_amount_rank
FROM returns r
LEFT JOIN pages_created pc ON r.c_customer_sk = pc.c_customer_sk
LEFT JOIN pages_accessed pa ON r.c_customer_sk = pa.c_customer_sk
WHERE r.num_returns >= 2
ORDER BY r.total_return_amount DESC
LIMIT 10
