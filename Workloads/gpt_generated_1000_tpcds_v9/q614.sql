WITH refunded_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_net_loss) AS net_loss_sum
    FROM catalog_returns cr
    FULL OUTER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_salutation = 'Dr.'
      AND r.r_reason_desc LIKE '%price%'
    GROUP BY r.r_reason_desc, cd.cd_gender
),
returning_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_net_loss) AS net_loss_sum
    FROM catalog_returns cr
    FULL OUTER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_salutation = 'Ms.'
      AND r.r_reason_id = 'AAAAAAAANAAAAAAA'
    GROUP BY r.r_reason_desc, cd.cd_gender
)
SELECT
    reason_desc,
    gender,
    return_cnt,
    net_loss_sum,
    SUM(net_loss_sum) OVER (PARTITION BY gender) AS gender_total_net_loss
FROM (
    SELECT reason_desc, gender, return_cnt, net_loss_sum FROM refunded_agg
    UNION ALL
    SELECT reason_desc, gender, return_cnt, net_loss_sum FROM returning_agg
) combined
ORDER BY gender_total_net_loss DESC
LIMIT 100
