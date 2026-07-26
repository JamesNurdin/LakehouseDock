WITH store_cust AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        d.d_year,
        SUM(sr.sr_fee) AS store_fee_total,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_fee > 0
    GROUP BY sr.sr_customer_sk, d.d_year
),
web_cust AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        d.d_year,
        SUM(wr.wr_fee) AS web_fee_total,
        COUNT(*) AS web_return_cnt,
        COUNT(DISTINCT wp.wp_type) AS distinct_page_types
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY wr.wr_refunded_customer_sk, d.d_year
),
cust_agg AS (
    SELECT
        COALESCE(s.customer_sk, w.customer_sk) AS customer_sk,
        COALESCE(s.d_year, w.d_year) AS year,
        COALESCE(s.store_fee_total, 0) + COALESCE(w.web_fee_total, 0) AS total_fee,
        COALESCE(s.store_return_cnt, 0) + COALESCE(w.web_return_cnt, 0) AS total_return_cnt,
        COALESCE(w.distinct_page_types, 0) AS page_type_count
    FROM store_cust s
    FULL OUTER JOIN web_cust w
        ON s.customer_sk = w.customer_sk AND s.d_year = w.d_year
)
SELECT
    ca.customer_sk,
    ca.year,
    ca.total_fee,
    ca.total_return_cnt,
    ca.page_type_count,
    AVG(ca.total_fee) OVER (PARTITION BY ca.year) AS avg_fee_per_year,
    SUM(ca.total_fee) OVER (PARTITION BY ca.customer_sk ORDER BY ca.year) AS cumulative_fee,
    ROW_NUMBER() OVER (PARTITION BY ca.year ORDER BY ca.total_fee DESC) AS fee_rank
FROM cust_agg ca
WHERE ca.year BETWEEN 2020 AND 2022
ORDER BY ca.year, ca.total_fee DESC
