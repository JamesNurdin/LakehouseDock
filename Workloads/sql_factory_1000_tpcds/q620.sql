WITH store_cust AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        d.d_year,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        SUM(sr.sr_return_amt) AS store_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_customer_sk, d.d_year
),
web_cust AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        d.d_year,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        SUM(wr.wr_return_amt) AS web_return_amt,
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
        COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
        COALESCE(s.store_return_qty, 0) + COALESCE(w.web_return_qty, 0) AS total_return_qty,
        COALESCE(s.store_return_amt, 0) + COALESCE(w.web_return_amt, 0) AS total_return_amt,
        COALESCE(w.distinct_page_types, 0) AS page_type_count
    FROM store_cust s
    FULL OUTER JOIN web_cust w
        ON s.customer_sk = w.customer_sk AND s.d_year = w.d_year
)
SELECT
    ca.customer_sk,
    ca.year,
    ca.total_net_loss,
    ca.total_return_qty,
    ca.total_return_amt,
    ca.page_type_count,
    RANK() OVER (PARTITION BY ca.year ORDER BY ca.total_net_loss DESC) AS yearly_customer_loss_rank,
    LAG(ca.total_net_loss) OVER (PARTITION BY ca.customer_sk ORDER BY ca.year) AS prev_year_net_loss,
    CASE
        WHEN LAG(ca.total_net_loss) OVER (PARTITION BY ca.customer_sk ORDER BY ca.year) IS NULL THEN NULL
        WHEN LAG(ca.total_net_loss) OVER (PARTITION BY ca.customer_sk ORDER BY ca.year) = 0 THEN NULL
        ELSE (ca.total_net_loss - LAG(ca.total_net_loss) OVER (PARTITION BY ca.customer_sk ORDER BY ca.year)) / LAG(ca.total_net_loss) OVER (PARTITION BY ca.customer_sk ORDER BY ca.year) * 100
    END AS net_loss_pct_change
FROM cust_agg ca
WHERE ca.year BETWEEN 2020 AND 2022
ORDER BY ca.year, ca.total_net_loss DESC
