WITH store_cust AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        d.d_quarter_seq,
        SUM(sr.sr_return_amt_inc_tax) AS store_return_amt_inc_tax,
        SUM(sr.sr_return_quantity) AS store_return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_customer_sk, d.d_quarter_seq
),
web_cust AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        d.d_quarter_seq,
        SUM(wr.wr_return_amt_inc_tax) AS web_return_amt_inc_tax,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        COUNT(DISTINCT wp.wp_type) AS distinct_page_types
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY wr.wr_refunded_customer_sk, d.d_quarter_seq
),
cust_agg AS (
    SELECT
        COALESCE(s.customer_sk, w.customer_sk) AS customer_sk,
        COALESCE(s.d_quarter_seq, w.d_quarter_seq) AS quarter_seq,
        COALESCE(s.store_return_amt_inc_tax, 0) + COALESCE(w.web_return_amt_inc_tax, 0) AS total_return_amt_inc_tax,
        COALESCE(s.store_return_qty, 0) + COALESCE(w.web_return_qty, 0) AS total_return_qty,
        COALESCE(w.distinct_page_types, 0) AS page_type_count
    FROM store_cust s
    FULL OUTER JOIN web_cust w
        ON s.customer_sk = w.customer_sk AND s.d_quarter_seq = w.d_quarter_seq
)
SELECT
    ca.customer_sk,
    ca.quarter_seq,
    ca.total_return_amt_inc_tax,
    ca.total_return_qty,
    ca.page_type_count,
    SUM(ca.total_return_amt_inc_tax) OVER (PARTITION BY ca.customer_sk ORDER BY ca.quarter_seq ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS rolling_4q_return_amt,
    RANK() OVER (PARTITION BY ca.quarter_seq ORDER BY ca.total_return_amt_inc_tax DESC) AS quarter_rank
FROM cust_agg ca
WHERE ca.quarter_seq BETWEEN 20201 AND 20204
ORDER BY ca.quarter_seq, ca.total_return_amt_inc_tax DESC
