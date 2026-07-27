WITH joined_data AS (
  SELECT
    d.d_date,
    d.d_year,
    s.s_store_id,
    s.s_store_name,
    s.s_number_employees,
    s.s_geography_class,
    cd_sr.cd_credit_rating,
    sr.sr_return_quantity,
    sr.sr_net_loss,
    wr.wr_return_quantity,
    wr.wr_net_loss,
    p.p_promo_id,
    p.p_cost,
    p.p_discount_active
  FROM date_dim d
  JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
  JOIN customer_demographics cd_sr
    ON cd_sr.cd_demo_sk = sr.sr_cdemo_sk
  LEFT JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
  LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
  LEFT JOIN customer_demographics cd_wr
    ON cd_wr.cd_demo_sk = wr.wr_returning_cdemo_sk
)
SELECT
  jd.d_date,
  jd.s_store_id,
  jd.s_store_name,
  SUM(jd.sr_net_loss) AS total_store_net_loss,
  SUM(COALESCE(jd.wr_net_loss, 0)) AS total_web_net_loss,
  SUM(jd.sr_net_loss) + SUM(COALESCE(jd.wr_net_loss, 0)) AS total_combined_net_loss,
  COUNT(DISTINCT jd.p_promo_id) AS promo_count,
  AVG(jd.p_cost) AS avg_promo_cost,
  (SELECT AVG(p2.p_cost) FROM promotion p2) AS overall_avg_promo_cost,
  RANK() OVER (PARTITION BY jd.d_date ORDER BY SUM(jd.sr_net_loss) + SUM(COALESCE(jd.wr_net_loss, 0)) DESC) AS loss_rank
FROM joined_data jd
WHERE jd.d_year = 2000
  AND jd.s_number_employees BETWEEN 200 AND 300
  AND jd.cd_credit_rating IN ('Good', 'High Risk')
  AND COALESCE(jd.p_discount_active, 'N') = 'Y'
  AND jd.s_geography_class <> 'Unknown'
  AND jd.sr_return_quantity > 0
GROUP BY
  jd.d_date,
  jd.s_store_id,
  jd.s_store_name
ORDER BY total_combined_net_loss DESC, loss_rank
LIMIT 100
