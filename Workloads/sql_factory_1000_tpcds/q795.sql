WITH catalog_agg AS (
   SELECT
      cd.cd_demo_sk,
      cd.cd_gender,
      cd.cd_marital_status,
      cd.cd_education_status,
      cc.cc_call_center_id,
      SUM(cr.cr_return_amt_inc_tax) AS catalog_return_amount,
      SUM(cr.cr_net_loss) AS catalog_net_loss,
      COUNT(*) AS catalog_return_cnt
   FROM catalog_returns cr
   JOIN customer_demographics cd
     ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cc.cc_call_center_id
),
web_agg AS (
   SELECT
      cd.cd_demo_sk,
      cd.cd_gender,
      cd.cd_marital_status,
      cd.cd_education_status,
      SUM(wr.wr_return_amt_inc_tax) AS web_return_amount,
      SUM(wr.wr_net_loss) AS web_net_loss,
      COUNT(*) AS web_return_cnt
   FROM web_returns wr
   JOIN customer_demographics cd
     ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT
   COALESCE(ca.cd_demo_sk, wa.cd_demo_sk) AS demo_sk,
   COALESCE(ca.cd_gender, wa.cd_gender) AS gender,
   COALESCE(ca.cd_marital_status, wa.cd_marital_status) AS marital_status,
   COALESCE(ca.cd_education_status, wa.cd_education_status) AS education_status,
   ca.cc_call_center_id,
   COALESCE(ca.catalog_return_amount, 0) AS catalog_return_amount,
   COALESCE(wa.web_return_amount, 0) AS web_return_amount,
   COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0) AS total_net_loss,
   COALESCE(ca.catalog_return_cnt, 0) AS catalog_return_cnt,
   COALESCE(wa.web_return_cnt, 0) AS web_return_cnt,
   DENSE_RANK() OVER (ORDER BY COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0) DESC) AS demographic_rank
FROM catalog_agg ca
FULL OUTER JOIN web_agg wa
  ON ca.cd_demo_sk = wa.cd_demo_sk
ORDER BY demographic_rank
LIMIT 10
