WITH preferred_customers AS (
    SELECT c_customer_sk
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
),
catalog_agg AS (
    SELECT
        cr.cr_refunded_customer_sk AS cust_sk,
        w.w_warehouse_name,
        r.r_reason_sk AS reason_sk,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_net_loss) AS cat_net_loss,
        AVG(cr.cr_return_amount) AS cat_avg_return_amt,
        COUNT(*) AS cat_return_cnt
    FROM catalog_returns cr
    JOIN preferred_customers pc ON cr.cr_refunded_customer_sk = pc.c_customer_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY cr.cr_refunded_customer_sk, w.w_warehouse_name, r.r_reason_sk, r.r_reason_desc
),
web_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS cust_sk,
        r.r_reason_sk AS reason_sk,
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_net_loss) AS web_net_loss,
        AVG(wr.wr_return_amt) AS web_avg_return_amt,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN preferred_customers pc ON wr.wr_refunded_customer_sk = pc.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY wr.wr_refunded_customer_sk, r.r_reason_sk, r.r_reason_desc
)
SELECT
    ca.w_warehouse_name,
    ca.reason_desc,
    COUNT(DISTINCT ca.cust_sk) AS distinct_customer_cnt,
    SUM(ca.cat_net_loss) AS total_catalog_net_loss,
    SUM(wa.web_net_loss) AS total_web_net_loss,
    SUM(ca.cat_net_loss) + SUM(wa.web_net_loss) AS combined_net_loss,
    AVG(ca.cat_avg_return_amt) AS avg_catalog_return_amount,
    AVG(wa.web_avg_return_amt) AS avg_web_return_amount,
    CASE
        WHEN SUM(ca.cat_net_loss) = 0 THEN NULL
        ELSE SUM(wa.web_net_loss) / SUM(ca.cat_net_loss)
    END AS web_to_catalog_loss_ratio,
    RANK() OVER (ORDER BY SUM(ca.cat_net_loss) + SUM(wa.web_net_loss) DESC) AS loss_rank
FROM catalog_agg ca
JOIN web_agg wa
    ON ca.cust_sk = wa.cust_sk
    AND ca.reason_sk = wa.reason_sk
GROUP BY ca.w_warehouse_name, ca.reason_desc
HAVING SUM(ca.cat_net_loss) + SUM(wa.web_net_loss) > 5000
ORDER BY loss_rank
LIMIT 10
