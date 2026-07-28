WITH
  st AS (
    SELECT
      sr.sr_returned_date_sk,
      d.d_year,
      i.i_item_id,
      i.i_current_price,
      sr.sr_net_loss,
      r.r_reason_desc,
      r.r_reason_sk,
      ca.ca_state,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ib.ib_upper_bound
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2002-12-31'
      AND i.i_current_price > 100
      AND ib.ib_upper_bound < 150000
  ),
  cat AS (
    SELECT
      cr.cr_returned_date_sk,
      d.d_year,
      i.i_item_id,
      i.i_current_price,
      cr.cr_net_loss,
      r.r_reason_desc,
      r.r_reason_sk,
      ca.ca_state,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ib.ib_upper_bound,
      cc.cc_name
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2002-12-31'
      AND i.i_current_price > 100
      AND cc.cc_employees > 3000000
  ),
  web AS (
    SELECT
      wr.wr_returned_date_sk,
      d.d_year,
      i.i_item_id,
      i.i_current_price,
      wr.wr_net_loss,
      r.r_reason_desc,
      r.r_reason_sk,
      ca.ca_state,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ib.ib_upper_bound,
      wp.wp_url
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2002-12-31'
      AND i.i_current_price > 100
      AND wp.wp_type = 'content'
  ),
  combined AS (
    SELECT d_year, r_reason_sk, r_reason_desc, sr_net_loss AS net_loss FROM st
    UNION ALL
    SELECT d_year, r_reason_sk, r_reason_desc, cr_net_loss FROM cat
    UNION ALL
    SELECT d_year, r_reason_sk, r_reason_desc, wr_net_loss FROM web
  )
SELECT
  c.d_year,
  c.r_reason_desc,
  SUM(c.net_loss) AS total_net_loss,
  CASE WHEN SUM(c.net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category,
  (SELECT COUNT(DISTINCT i_item_id) FROM item) AS distinct_item_count
FROM combined c
WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_reason_sk = c.r_reason_sk
          AND wr2.wr_net_loss > 5000
      )
GROUP BY c.d_year, c.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
