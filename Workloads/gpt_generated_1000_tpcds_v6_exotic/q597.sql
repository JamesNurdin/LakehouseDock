WITH aggregated_data AS (
    SELECT
        cc.cc_company_name,
        s.s_state AS store_state,
        s.s_city,
        cd.cd_gender,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        CASE WHEN SUM(sr.sr_net_loss) > 5000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN catalog_returns cr
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_company_name = 'cally'
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'F'
    GROUP BY cc.cc_company_name, s.s_state, s.s_city, cd.cd_gender
    HAVING SUM(sr.sr_net_loss) > 1000
)
SELECT
    *,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated_data
ORDER BY total_net_loss DESC
LIMIT 100
