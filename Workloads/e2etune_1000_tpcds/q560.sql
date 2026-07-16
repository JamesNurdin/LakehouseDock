WITH promo_sales AS (
  SELECT
    p.p_promo_sk,
    p.p_promo_name,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
  JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE d_sales.d_date BETWEEN d_start.d_date AND d_end.d_date
    AND cd.cd_marital_status = 'M'
    AND cd.cd_gender = 'F'
  GROUP BY p.p_promo_sk, p.p_promo_name
),

promo_store_returns AS (
  SELECT
    p.p_promo_sk,
    SUM(sr.sr_net_loss) AS total_store_loss
  FROM store_returns sr
  JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  CROSS JOIN promotion p
  JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
  JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
  WHERE r.r_reason_desc = 'Damaged'
    AND d_sr.d_date BETWEEN d_start.d_date AND d_end.d_date
  GROUP BY p.p_promo_sk
),

promo_web_returns AS (
  SELECT
    p.p_promo_sk,
    SUM(wr.wr_net_loss) AS total_web_loss
  FROM web_returns wr
  JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  CROSS JOIN promotion p
  JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
  JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
  WHERE r.r_reason_desc = 'Damaged'
    AND d_wr.d_date BETWEEN d_start.d_date AND d_end.d_date
  GROUP BY p.p_promo_sk
)

SELECT
  ps.p_promo_name,
  ps.total_sales_profit,
  COALESCE(psr.total_store_loss, 0) AS total_store_loss,
  COALESCE(pwr.total_web_loss, 0) AS total_web_loss,
  (ps.total_sales_profit - COALESCE(psr.total_store_loss, 0) - COALESCE(pwr.total_web_loss, 0)) AS net_profit_after_returns,
  RANK() OVER (ORDER BY (ps.total_sales_profit - COALESCE(psr.total_store_loss, 0) - COALESCE(pwr.total_web_loss, 0)) DESC) AS profit_rank
FROM promo_sales ps
LEFT JOIN promo_store_returns psr ON ps.p_promo_sk = psr.p_promo_sk
LEFT JOIN promo_web_returns pwr ON ps.p_promo_sk = pwr.p_promo_sk
WHERE (ps.total_sales_profit - COALESCE(psr.total_store_loss, 0) - COALESCE(pwr.total_web_loss, 0)) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 10
