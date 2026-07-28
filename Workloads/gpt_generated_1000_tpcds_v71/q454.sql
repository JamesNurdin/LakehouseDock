WITH cr_agg AS (
    SELECT
        cr_call_center_sk,
        cr_ship_mode_sk,
        cr_refunded_cdemo_sk,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_return_amount)   AS total_return_amount,
        SUM(cr_net_loss)        AS total_net_loss
    FROM catalog_returns
    WHERE cr_return_amount > 100
      AND cr_return_tax    > 0
      AND cr_return_quantity > 0
      AND cr_fee            < 500
    GROUP BY cr_call_center_sk, cr_ship_mode_sk, cr_refunded_cdemo_sk
)
SELECT
    cc.cc_name,
    sm.sm_type,
    cd.cd_gender,
    SUM(cr_agg.total_return_qty)    AS agg_return_qty,
    SUM(cr_agg.total_return_amount) AS agg_return_amount,
    SUM(ws.ws_net_profit)           AS total_web_profit,
    SUM(sr.sr_return_amt)           AS total_store_return_amt
FROM cr_agg
JOIN call_center cc
  ON cr_agg.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON cr_agg.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
  ON cr_agg.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN store_returns sr
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN web_sales ws
  ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
WHERE cc.cc_state               = 'TX'
  AND sm.sm_carrier             = 'UPS'
  AND cd.cd_education_status    = 'College'
  AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
GROUP BY cc.cc_name, sm.sm_type, cd.cd_gender
HAVING SUM(cr_agg.total_return_amount) > 1000
ORDER BY agg_return_amount DESC
LIMIT 100
