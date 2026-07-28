WITH store_web AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        wr.wr_refunded_cash,
        wr.wr_returned_date_sk,
        CASE WHEN sr.sr_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_category
    FROM tpcds.store_returns sr
    JOIN tpcds.date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND d.d_moy = 5
      AND c.c_birth_year BETWEEN 1950 AND 1960
      AND c.c_preferred_cust_flag = 'Y'
      AND sr.sr_return_amt > 50
      AND wr.wr_refunded_cash < 500
)
SELECT
    loss_category,
    COUNT(*) AS return_count,
    SUM(sr_net_loss) AS total_net_loss,
    AVG(wr_refunded_cash) AS avg_refunded_cash,
    MIN(sr_return_amt) AS min_return_amt,
    MAX(sr_return_amt) AS max_return_amt
FROM store_web
WHERE EXISTS (
    SELECT 1
    FROM tpcds.web_returns wr2
    WHERE wr2.wr_returning_customer_sk = store_web.sr_customer_sk
      AND wr2.wr_returned_date_sk = store_web.sr_returned_date_sk
      AND wr2.wr_refunded_cash > 200
)
GROUP BY loss_category
ORDER BY total_net_loss DESC
LIMIT 10
