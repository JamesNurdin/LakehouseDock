WITH store_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        sr.sr_return_amt AS return_amt,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS return_quantity
    FROM store_returns sr
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
),
catalog_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        cr.cr_return_amount AS return_amt,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS return_quantity
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
),
web_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        wr.wr_return_amt AS return_amt,
        wr.wr_net_loss AS net_loss,
        wr.wr_return_quantity AS return_quantity
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
),
all_returns AS (
    SELECT reason_desc, gender, marital_status, return_amt, net_loss, return_quantity
    FROM store_ret
    UNION ALL
    SELECT reason_desc, gender, marital_status, return_amt, net_loss, return_quantity
    FROM catalog_ret
    UNION ALL
    SELECT reason_desc, gender, marital_status, return_amt, net_loss, return_quantity
    FROM web_ret
)
SELECT
    reason_desc,
    gender,
    marital_status,
    COUNT(*) AS total_returns,
    SUM(return_amt) AS total_return_amount,
    SUM(net_loss) AS total_net_loss,
    AVG(return_amt) AS avg_return_amount,
    SUM(return_quantity) AS total_quantity
FROM all_returns
GROUP BY reason_desc, gender, marital_status
ORDER BY total_net_loss DESC
LIMIT 20
