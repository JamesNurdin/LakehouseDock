SELECT
  ib_lower_bound,
  ib_upper_bound,
  total_profit,
  sales_cnt,
  promo_type
FROM (
  SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    'Email_AM' AS promo_type
  FROM catalog_sales cs
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE p.p_channel_email = 'Y'
    AND t.t_shift = 'AM'
    AND cs.cs_list_price > 100
  GROUP BY ib.ib_lower_bound, ib.ib_upper_bound

  UNION ALL

  SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    'Press_PM' AS promo_type
  FROM catalog_sales cs
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE p.p_channel_press = 'Y'
    AND t.t_shift = 'PM'
    AND cs.cs_list_price > 100
  GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
) AS combined
ORDER BY ib_lower_bound, promo_type
LIMIT 100
