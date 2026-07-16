WITH agg_returns AS (
  SELECT
    demo_ret.cd_gender AS returning_gender,
    demo_ret.cd_marital_status AS returning_marital_status,
    demo_ref.cd_gender AS refunded_gender,
    demo_ref.cd_marital_status AS refunded_marital_status,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_cnt
  FROM web_returns wr
  JOIN customer cust_ret
    ON wr.wr_returning_customer_sk = cust_ret.c_customer_sk
  JOIN customer_demographics demo_ret
    ON wr.wr_returning_cdemo_sk = demo_ret.cd_demo_sk
  JOIN customer cust_ref
    ON wr.wr_refunded_customer_sk = cust_ref.c_customer_sk
  JOIN customer_demographics demo_ref
    ON wr.wr_refunded_cdemo_sk = demo_ref.cd_demo_sk
  WHERE cust_ret.c_birth_country = 'United States'
    AND demo_ret.cd_gender = 'M'
    AND demo_ret.cd_education_status = 'College'
    AND wr.wr_return_amt_inc_tax > 0
  GROUP BY demo_ret.cd_gender,
           demo_ret.cd_marital_status,
           demo_ref.cd_gender,
           demo_ref.cd_marital_status
  HAVING SUM(wr.wr_return_amt_inc_tax) > 1000
)
SELECT
  returning_gender,
  returning_marital_status,
  refunded_gender,
  refunded_marital_status,
  total_return_amount_inc_tax,
  total_net_loss,
  avg_return_quantity,
  return_cnt,
  (total_net_loss / NULLIF(total_return_amount_inc_tax, 0)) AS loss_ratio,
  RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank,
  (SELECT AVG(cc_tax_percentage) FROM call_center WHERE cc_country = 'United States') AS avg_us_cc_tax_pct
FROM agg_returns
ORDER BY loss_rank
LIMIT 20
