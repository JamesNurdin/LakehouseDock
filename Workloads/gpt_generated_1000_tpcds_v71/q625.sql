WITH filtered AS (
  SELECT
    ss.ss_store_sk,
    d.d_year,
    cd.cd_credit_rating,
    cd.cd_education_status,
    ss.ss_ext_tax,
    ss.ss_net_profit,
    ws.ws_net_profit AS ws_net_profit,
    cr.cr_fee,
    cr.cr_return_amount,
    cc.cc_name,
    cp.cp_type
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
  LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND cd.cd_credit_rating = 'High Risk'
    AND cd.cd_education_status = 'College'
    AND ss.ss_ext_tax > 10
    AND cr.cr_fee < 50
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returning_cdemo_sk = cd.cd_demo_sk
          AND cr2.cr_fee > 100
    )
)
SELECT
  f.ss_store_sk,
  f.d_year,
  f.cd_credit_rating,
  f.cd_education_status,
  SUM(f.ss_net_profit) AS total_store_profit,
  SUM(f.ws_net_profit) AS total_web_profit,
  COUNT(DISTINCT f.cc_name) AS distinct_call_centers,
  DENSE_RANK() OVER (PARTITION BY f.d_year ORDER BY SUM(f.ss_net_profit) + SUM(f.ws_net_profit) DESC) AS profit_rank
FROM filtered f
GROUP BY
  f.ss_store_sk,
  f.d_year,
  f.cd_credit_rating,
  f.cd_education_status
HAVING SUM(f.ss_net_profit) + SUM(f.ws_net_profit) > 1000
ORDER BY profit_rank ASC, total_store_profit DESC
LIMIT 100
