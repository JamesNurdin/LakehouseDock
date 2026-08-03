WITH refunded AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        dt.d_year,
        mc.monthly_item_cnt
    FROM web_returns wr
    JOIN date_dim dt ON wr.wr_returned_date_sk = dt.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(DISTINCT wr2.wr_item_sk) AS monthly_item_cnt
        FROM web_returns wr2
        WHERE wr2.wr_returned_date_sk = wr.wr_returned_date_sk
    ) AS mc
    WHERE dt.d_year = 2000
      AND c.c_customer_sk NOT IN (SELECT c2.c_customer_sk FROM customer c2 WHERE c2.c_preferred_cust_flag = 'Y')
    GROUP BY
        wr.wr_refunded_customer_sk,
        c.c_first_name,
        c.c_last_name,
        dt.d_year,
        mc.monthly_item_cnt
    HAVING SUM(wr.wr_return_amt) > 1000
),
returning AS (
    SELECT
        wr.wr_returning_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        dt.d_year,
        mc.monthly_item_cnt
    FROM web_returns wr
    JOIN date_dim dt ON wr.wr_returned_date_sk = dt.d_date_sk
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(DISTINCT wr2.wr_item_sk) AS monthly_item_cnt
        FROM web_returns wr2
        WHERE wr2.wr_returned_date_sk = wr.wr_returned_date_sk
    ) AS mc
    WHERE dt.d_year = 2000
      AND i.i_brand = 'Brand#12'
      AND c.c_customer_sk NOT IN (SELECT c2.c_customer_sk FROM customer c2 WHERE c2.c_preferred_cust_flag = 'Y')
    GROUP BY
        wr.wr_returning_customer_sk,
        c.c_first_name,
        c.c_last_name,
        dt.d_year,
        mc.monthly_item_cnt
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    customer_sk,
    c_first_name,
    c_last_name,
    total_return_amt,
    return_cnt,
    d_year,
    monthly_item_cnt
FROM (
    SELECT * FROM refunded
    UNION ALL
    SELECT * FROM returning
) AS combined
ORDER BY total_return_amt DESC
LIMIT 100
