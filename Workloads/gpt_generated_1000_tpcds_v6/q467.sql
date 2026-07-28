WITH base AS (
  SELECT
    s.s_store_id,
    s.s_geography_class,
    p.p_channel_email,
    r.r_reason_desc,
    ss.ss_net_paid          AS ss_net_paid,
    ss.ss_net_profit        AS ss_net_profit,
    cs.cs_net_paid          AS cs_net_paid,
    cs.cs_net_profit        AS cs_net_profit,
    sr.sr_return_amt        AS sr_return_amt,
    sr.sr_net_loss          AS sr_net_loss
  FROM store_sales ss
  JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
  JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
  LEFT JOIN income_band ib_ss
    ON hd_ss.hd_income_band_sk = ib_ss.ib_income_band_sk

  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
  LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
  LEFT JOIN store s_ret
    ON sr.sr_store_sk = s_ret.s_store_sk
  LEFT JOIN customer_demographics cd_ret
    ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
  LEFT JOIN household_demographics hd_ret
    ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
  LEFT JOIN income_band ib_ret
    ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk

  LEFT JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
   AND cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  LEFT JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  LEFT JOIN income_band ib_bill
    ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
  LEFT JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  LEFT JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  LEFT JOIN income_band ib_ship
    ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
)
SELECT
  s_store_id,
  s_geography_class,
  p_channel_email,
  r_reason_desc,
  SUM(COALESCE(ss_net_paid, 0) + COALESCE(cs_net_paid, 0) - COALESCE(sr_return_amt, 0)) AS total_revenue,
  SUM(COALESCE(ss_net_profit, 0) + COALESCE(cs_net_profit, 0) - COALESCE(sr_net_loss, 0)) AS total_profit,
  ROW_NUMBER() OVER (PARTITION BY s_geography_class ORDER BY SUM(COALESCE(ss_net_paid, 0) + COALESCE(cs_net_paid, 0) - COALESCE(sr_return_amt, 0)) DESC) AS revenue_rank
FROM base
GROUP BY
  GROUPING SETS (
    (s_store_id, s_geography_class, p_channel_email, r_reason_desc),
    (s_store_id, s_geography_class, p_channel_email),
    (s_store_id, s_geography_class),
    (s_geography_class)
  )
ORDER BY
  total_revenue DESC,
  s_geography_class
LIMIT 100
