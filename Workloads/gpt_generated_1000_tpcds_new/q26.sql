WITH per_store_reason AS (
  SELECT
    s.s_store_id,
    r.r_reason_id,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_net_paid) AS total_sales_net,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(ws.ws_net_paid) AS total_web_net,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales_price,
    SUM(ws.ws_ext_sales_price) AS total_web_ext_sales
  FROM store_sales ss
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_cdemo_sk = cd.cd_demo_sk
   AND sr.sr_hdemo_sk = hd.hd_demo_sk
   AND sr.sr_store_sk = s.s_store_sk
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN web_sales ws
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'M'
    AND cd.cd_purchase_estimate >= 5000
    AND hd.hd_vehicle_count >= 1
    AND r.r_reason_desc LIKE '%service%'
    AND s.s_state = 'CA'
  GROUP BY s.s_store_id, r.r_reason_id
),
per_store AS (
  SELECT
    s_store_id,
    AVG(total_sales_net) AS avg_sales_net,
    SUM(total_sales_net) AS sum_sales_net,
    COUNT(*) AS reason_cnt
  FROM per_store_reason
  GROUP BY s_store_id
)
SELECT
  ps.s_store_id,
  ps.avg_sales_net,
  ps.sum_sales_net,
  ps.reason_cnt,
  LAG(ps.sum_sales_net) OVER (ORDER BY ps.sum_sales_net DESC) AS lag_sum_sales_net,
  SUM(ps.sum_sales_net) OVER (
    ORDER BY ps.sum_sales_net DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_sum_sales_net
FROM per_store ps
WHERE ps.avg_sales_net > 15000
ORDER BY ps.sum_sales_net DESC
LIMIT 100
