WITH returns_by_customer_year AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt,
        AVG(sr.sr_return_amt) AS avg_return_amt
    FROM tpcds.store_returns sr
    JOIN tpcds.date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.promotion p
        ON d.d_date_sk = p.p_start_date_sk
    WHERE
        d.d_weekend = 'N'
        AND d.d_fy_week_seq BETWEEN 5 AND 15
        AND d.d_year = 2002
        AND sr.sr_return_amt > 100.00
        AND sr.sr_return_quantity >= 1
        AND p.p_channel_demo = 'N'
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY c.c_customer_id, d.d_year
)
SELECT
    c_customer_id,
    d_year,
    total_return_amt,
    total_return_qty,
    return_cnt,
    avg_return_amt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS rank_by_return,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY avg_return_amt DESC) AS row_by_avg,
    SUM(total_return_amt) OVER (
        PARTITION BY d_year
        ORDER BY total_return_amt DESC
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS running_total_last_3
FROM returns_by_customer_year
ORDER BY d_year, rank_by_return
LIMIT 100
