WITH
  date_filtered AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
  ),
  store_f AS (
    SELECT s.s_store_sk,
           s.s_store_id,
           s.s_store_name,
           d.d_year
    FROM store s
    JOIN date_filtered d ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_state = 'CA'
  ),
  ss_agg AS (
    SELECT ss.ss_store_sk,
           d.d_year,
           SUM(ss.ss_net_profit) AS ss_profit
    FROM store_sales ss
    JOIN date_filtered d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = 'HIGH'
    GROUP BY ss.ss_store_sk, d.d_year
  ),
  sr_agg AS (
    SELECT sr.sr_store_sk,
           d.d_year,
           SUM(sr.sr_net_loss) AS sr_loss
    FROM store_returns sr
    JOIN date_filtered d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE r.r_reason_desc = 'Customer Not Satisfied'
      AND cd.cd_marital_status = 'M'
      AND hd.hd_vehicle_count > 1
    GROUP BY sr.sr_store_sk, d.d_year
  ),
  cs_agg AS (
    SELECT d.d_year,
           SUM(cs.cs_net_profit) AS cs_profit
    FROM catalog_sales cs
    JOIN date_filtered d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND t.t_hour BETWEEN 9 AND 18
      AND cd.cd_gender = 'F'
      AND hd.hd_buy_potential = 'LOW'
    GROUP BY d.d_year
  ),
  wr_agg AS (
    SELECT d.d_year,
           SUM(wr.wr_net_loss) AS wr_loss
    FROM web_returns wr
    JOIN date_filtered d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wp.wp_max_ad_count > 1
      AND cd.cd_education_status = 'College'
      AND hd.hd_income_band_sk = 5
    GROUP BY d.d_year
  )
SELECT
  sf.s_store_id,
  sf.s_store_name,
  sf.d_year,
  COALESCE(ss_agg.ss_profit, 0) + COALESCE(cs_agg.cs_profit, 0)
    - COALESCE(sr_agg.sr_loss, 0) - COALESCE(wr_agg.wr_loss, 0) AS total_profit,
  RANK() OVER (
    PARTITION BY sf.d_year
    ORDER BY COALESCE(ss_agg.ss_profit, 0) + COALESCE(cs_agg.cs_profit, 0)
            - COALESCE(sr_agg.sr_loss, 0) - COALESCE(wr_agg.wr_loss, 0) DESC
  ) AS profit_rank
FROM store_f sf
LEFT JOIN ss_agg ON ss_agg.ss_store_sk = sf.s_store_sk AND ss_agg.d_year = sf.d_year
LEFT JOIN sr_agg ON sr_agg.sr_store_sk = sf.s_store_sk AND sr_agg.d_year = sf.d_year
LEFT JOIN cs_agg ON cs_agg.d_year = sf.d_year
LEFT JOIN wr_agg ON wr_agg.d_year = sf.d_year
ORDER BY sf.d_year, total_profit DESC
LIMIT 100
