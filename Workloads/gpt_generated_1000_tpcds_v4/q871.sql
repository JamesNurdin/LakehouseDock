WITH cs_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_mode_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_call_center_sk,
             cs.cs_sold_date_sk,
             cs.cs_sold_time_sk,
             cs.cs_bill_cdemo_sk,
             cs.cs_ship_mode_sk
),
sr_agg AS (
    SELECT
        sr.sr_returned_date_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk
),
wr_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    cc.cc_call_center_id,
    d.d_year,
    sm.sm_type,
    cd.cd_gender,
    SUM(ca.total_net_paid) AS sum_net_paid,
    SUM(ca.total_net_profit) AS sum_net_profit,
    SUM(sr.total_return_loss) AS sum_return_loss,
    SUM(wr.total_web_return_loss) AS sum_web_return_loss,
    (SUM(ca.total_net_paid) + SUM(ca.total_net_profit) - SUM(sr.total_return_loss) - SUM(wr.total_web_return_loss)) AS net_impact,
    RANK() OVER (PARTITION BY d.d_year ORDER BY (SUM(ca.total_net_paid) + SUM(ca.total_net_profit) - SUM(sr.total_return_loss) - SUM(wr.total_web_return_loss)) DESC) AS impact_rank
FROM cs_agg ca
JOIN call_center cc ON ca.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON ca.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d ON ca.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ca.cs_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd ON ca.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN sr_agg sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN wr_agg wr ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND cc.cc_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND cd.cd_gender = 'F'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY cc.cc_call_center_id, d.d_year, sm.sm_type, cd.cd_gender
HAVING (SUM(ca.total_net_paid) + SUM(ca.total_net_profit) - SUM(sr.total_return_loss) - SUM(wr.total_web_return_loss)) > 0
   AND SUM(sr.total_return_loss) > 0
   AND SUM(wr.total_web_return_loss) > 0
ORDER BY net_impact DESC
LIMIT 100
