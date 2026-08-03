WITH
  store_data AS (
    SELECT
      sr.sr_store_sk,
      s.s_city,
      s.s_state,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      r.r_reason_desc,
      td.t_meal_time,
      sr.sr_return_amt,
      CASE WHEN sr.sr_net_loss > 0 THEN 'Loss' ELSE 'NoLoss' END AS loss_flag,
      ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY sr.sr_return_amt DESC) AS rn_state
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE s.s_city IN ('Fairview', 'Riverside')
      AND s.s_number_employees > 200
      AND td.t_meal_time = 'lunch'
      AND cd.cd_gender = 'F'
      AND ib.ib_upper_bound <= 50000
  ),
  web_data AS (
    SELECT
      wr.wr_web_page_sk,
      wp.wp_type,
      wp.wp_url,
      cd.cd_marital_status,
      hd.hd_buy_potential,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      r.r_reason_desc,
      td.t_meal_time,
      wr.wr_return_amt,
      CASE WHEN wr.wr_net_loss > 0 THEN 'Loss' ELSE 'NoLoss' END AS loss_flag,
      ROW_NUMBER() OVER (PARTITION BY wp.wp_type ORDER BY wr.wr_return_amt DESC) AS rn_type
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE wp.wp_type = 'article'
      AND wp.wp_char_count BETWEEN 500 AND 2000
      AND td.t_meal_time = 'dinner'
      AND cd.cd_marital_status = 'M'
      AND ib.ib_lower_bound >= 0
  ),
  unioned AS (
    SELECT
      'store' AS source,
      s_city AS location,
      sr_return_amt AS return_amount,
      loss_flag,
      rn_state AS row_num
    FROM store_data
    WHERE rn_state <= 5

    UNION DISTINCT

    SELECT
      'web' AS source,
      wp_type AS location,
      wr_return_amt AS return_amount,
      loss_flag,
      rn_type AS row_num
    FROM web_data
    WHERE rn_type <= 5
  )
SELECT
  source,
  location,
  return_amount,
  loss_flag,
  row_num,
  RANK() OVER (ORDER BY return_amount DESC) AS overall_rank,
  (SELECT MAX(sr_return_amt) FROM store_returns) AS max_store_return_amt,
  AVG(return_amount) OVER (PARTITION BY source) AS avg_return_by_source
FROM unioned
ORDER BY overall_rank
LIMIT 100
