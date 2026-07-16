WITH combined AS (
    SELECT
        cc.cc_division_name AS division,
        r.r_reason_desc AS reason,
        cd.cd_gender AS gender,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_tax AS return_tax
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2453650
    UNION ALL
    SELECT
        'Web' AS division,
        r.r_reason_desc AS reason,
        cd.cd_gender AS gender,
        wr.wr_net_loss AS net_loss,
        wr.wr_return_amt AS return_amount,
        wr.wr_return_tax AS return_tax
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2453650
)
SELECT
    division,
    reason,
    gender,
    SUM(net_loss) AS total_net_loss,
    SUM(return_amount) AS total_return_amount,
    SUM(return_tax) AS total_return_tax,
    CASE
        WHEN SUM(return_amount) = 0 THEN 0
        ELSE SUM(net_loss) / SUM(return_amount)
    END AS loss_to_return_ratio
FROM combined
GROUP BY division, reason, gender
HAVING SUM(net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 20
