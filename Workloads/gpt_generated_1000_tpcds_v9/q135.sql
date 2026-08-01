WITH daily_returns AS (
    SELECT
        d.d_date AS return_date,
        d.d_year AS return_year,
        ca.ca_state,
        cd.cd_gender,
        wp.wp_type,
        SUM(wr.wr_return_amt) AS sum_return_amt,
        SUM(wr.wr_return_quantity) AS sum_return_qty,
        COUNT(*) AS txn_cnt,
        CASE WHEN SUM(wr.wr_return_amt) > 500 THEN 'High' ELSE 'Low' END AS high_low_flag
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND cd.cd_gender = 'F'
      AND wp.wp_type = 'Product'
      AND wr.wr_return_amt > 20.0
    GROUP BY d.d_date, d.d_year, ca.ca_state, cd.cd_gender, wp.wp_type
)
SELECT
    return_year,
    ca_state,
    high_low_flag,
    GROUPING(return_year) AS g_return_year,
    GROUPING(ca_state) AS g_state,
    GROUPING(high_low_flag) AS g_flag,
    SUM(sum_return_amt) AS total_return_amt,
    AVG(sum_return_amt) AS avg_return_amt_per_day,
    SUM(sum_return_qty) AS total_return_qty,
    SUM(txn_cnt) AS total_txn_cnt
FROM daily_returns
GROUP BY GROUPING SETS (
    (return_year, ca_state, high_low_flag),
    (return_year, ca_state),
    (return_year),
    ()
)
HAVING SUM(sum_return_amt) > 1000
ORDER BY total_return_amt DESC
