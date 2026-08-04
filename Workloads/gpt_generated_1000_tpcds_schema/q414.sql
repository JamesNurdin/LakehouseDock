WITH
    agg_returns AS (
        SELECT
            sr_customer_sk,
            sr_returned_date_sk,
            sr_return_time_sk,
            SUM(sr_return_amt_inc_tax) AS total_return_amt,
            SUM(sr_fee) AS total_fee,
            COUNT(*) AS return_cnt,
            MIN(sr_return_quantity) AS min_qty,
            MAX(sr_return_quantity) AS max_qty
        FROM tpcds.store_returns
        TABLESAMPLE BERNOULLI (10)
        WHERE sr_fee > 20
        GROUP BY sr_customer_sk, sr_returned_date_sk, sr_return_time_sk
    ),
    intersect_customers AS (
        SELECT DISTINCT wp_customer_sk AS c_sk
        FROM tpcds.web_page
        WHERE wp_type = 'article' AND wp_link_count > 5
        INTERSECT
        SELECT DISTINCT sr_customer_sk
        FROM tpcds.store_returns
        WHERE sr_fee > 30
    )
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_ret.d_year,
    t.t_hour,
    wp.wp_type,
    SUM(ar.total_return_amt) AS sum_return_amount,
    AVG(ar.total_fee) AS avg_fee_per_return,
    COUNT(DISTINCT ar.sr_returned_date_sk) AS distinct_return_dates,
    MIN(ar.min_qty) AS overall_min_qty,
    MAX(ar.max_qty) AS overall_max_qty
FROM agg_returns ar
JOIN tpcds.customer c
    ON ar.sr_customer_sk = c.c_customer_sk
JOIN tpcds.date_dim d_ret
    ON ar.sr_returned_date_sk = d_ret.d_date_sk
JOIN tpcds.time_dim t
    ON ar.sr_return_time_sk = t.t_time_sk
JOIN tpcds.household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN tpcds.date_dim d_wp
    ON wp.wp_creation_date_sk = d_wp.d_date_sk
WHERE
    d_ret.d_year = 2000
    AND d_ret.d_moy IN (5, 6)
    AND t.t_am_pm = 'PM'
    AND hd.hd_vehicle_count >= 1
    AND wp.wp_link_count > 7
    AND c.c_customer_sk IN (SELECT c_sk FROM intersect_customers)
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_ret.d_year,
    t.t_hour,
    wp.wp_type
HAVING
    SUM(ar.total_return_amt) > 1000
ORDER BY sum_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
