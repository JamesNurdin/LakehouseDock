WITH joined_data AS (
    SELECT
        cc.cc_call_center_id,
        cr.cr_returning_customer_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        r.r_reason_desc,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr
        ON wr.wr_reason_sk = r.r_reason_sk
       AND wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND cd.cd_marital_status IN ('M', 'S')
      AND cr.cr_return_amount > 1000
),
agg_by_center_reason AS (
    SELECT
        cc_call_center_id,
        r_reason_desc,
        SUM(cr_return_amount) AS total_catalog_return,
        SUM(wr_return_amt) AS total_web_return,
        COUNT(*) AS txn_count,
        AVG(cr_return_amount) AS avg_catalog_return
    FROM joined_data
    GROUP BY cc_call_center_id, r_reason_desc
    HAVING (SUM(cr_return_amount) + SUM(wr_return_amt)) > 5000
       AND COUNT(*) >= 10
       AND AVG(cr_return_amount) > 500
)
SELECT
    cc_call_center_id,
    r_reason_desc,
    total_catalog_return,
    total_web_return,
    (total_catalog_return + total_web_return) AS total_combined_return,
    SUM(total_catalog_return + total_web_return) OVER (
        ORDER BY total_catalog_return + total_web_return DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return,
    RANK() OVER (ORDER BY total_catalog_return + total_web_return DESC) AS return_rank
FROM agg_by_center_reason
ORDER BY total_combined_return DESC
LIMIT 100
