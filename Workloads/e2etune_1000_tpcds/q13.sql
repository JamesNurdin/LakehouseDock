WITH filtered_sales AS (
  SELECT
    ss.ss_sold_time_sk,
    ss.ss_net_profit,
    ss.ss_ext_discount_amt
  FROM store_sales ss
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE hd.hd_income_band_sk >= 4
    AND hd.hd_vehicle_count >= 2
    AND p.p_response_target = 1
    AND p.p_discount_active = 'Y'
    AND ss.ss_net_profit > 0
),
hourly_agg AS (
  SELECT
    td.t_hour,
    SUM(fs.ss_net_profit) AS total_profit,
    AVG(fs.ss_ext_discount_amt) AS avg_discount_amount,
    COUNT(*) AS sales_count
  FROM filtered_sales fs
  JOIN time_dim td ON fs.ss_sold_time_sk = td.t_time_sk
  GROUP BY td.t_hour
)
SELECT
  ha.t_hour,
  ha.total_profit,
  ha.avg_discount_amount,
  ha.sales_count,
  RANK() OVER (ORDER BY ha.total_profit DESC) AS profit_rank,
  SUM(ha.total_profit) OVER (ORDER BY ha.t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_by_hour
FROM hourly_agg ha
ORDER BY ha.total_profit DESC
