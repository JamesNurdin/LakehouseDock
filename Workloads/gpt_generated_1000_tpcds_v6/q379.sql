WITH base AS (
  SELECT
    cd.cd_gender,
    cd.cd_education_status,
    sr.sr_net_loss,
    sr.sr_return_amt,
    s.s_state,
    r.r_reason_desc,
    r.r_reason_id,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cc.cc_market_manager,
    wr.wr_refunded_cash,
    wr.wr_return_amt_inc_tax
  FROM tpcds.customer_demographics cd
  JOIN tpcds.store_returns sr
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.store s
    ON sr.sr_store_sk = s.s_store_sk
  JOIN tpcds.reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN tpcds.catalog_returns cr
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   AND cr.cr_reason_sk = r.r_reason_sk
  JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   AND wr.wr_reason_sk = r.r_reason_sk
  WHERE cd.cd_gender = 'M'
    AND cd.cd_education_status = 'College'
    AND r.r_reason_id = 'AAAAAAAAGAAAAAAA'
    AND s.s_state = 'CA'
    AND cc.cc_market_manager = 'John Doe'
    AND cr.cr_return_amount > 100.00
    AND wr.wr_refunded_cash < 200.00
    AND EXISTS (
        SELECT 1 FROM tpcds.web_returns wr2
        WHERE wr2.wr_reason_sk = r.r_reason_sk
          AND wr2.wr_refunded_cash > 500.00
    )
)
SELECT
  cd_gender,
  cd_education_status,
  s_state,
  r_reason_desc,
  COUNT(DISTINCT cr_return_quantity) AS distinct_return_qty,
  SUM(cr_return_amount) AS total_return_amount,
  SUM(sr_net_loss) AS total_store_net_loss,
  AVG(wr_refunded_cash) AS avg_refunded_cash,
  (SELECT AVG(sr_net_loss) FROM tpcds.store_returns) AS overall_avg_store_net_loss
FROM base
GROUP BY cd_gender, cd_education_status, s_state, r_reason_desc
HAVING SUM(cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
