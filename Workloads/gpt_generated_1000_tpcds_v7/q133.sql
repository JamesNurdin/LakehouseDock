WITH
  cr_agg AS (
    SELECT
      d_ret.d_year AS year,
      sm.sm_contract AS ship_contract,
      r.r_reason_desc AS return_reason,
      cd_ret.cd_gender AS gender,
      SUM(cr.cr_net_loss) AS total_return_net_loss,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd_ret
      ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    GROUP BY d_ret.d_year, sm.sm_contract, r.r_reason_desc, cd_ret.cd_gender
  ),
  ss_agg AS (
    SELECT
      d_sold.d_year AS year,
      SUM(ss.ss_net_profit) AS total_store_profit,
      COUNT(*) AS store_cnt
    FROM store_sales ss
    JOIN date_dim d_sold
      ON ss.ss_sold_date_sk = d_sold.d_date_sk
    GROUP BY d_sold.d_year
  ),
  ws_agg AS (
    SELECT
      d_ws.d_year AS year,
      SUM(ws.ws_net_profit) AS total_web_profit,
      COUNT(*) AS web_cnt
    FROM web_sales ws
    JOIN date_dim d_ws
      ON ws.ws_sold_date_sk = d_ws.d_date_sk
    LEFT JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN ship_mode sm_ws
      ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN customer_demographics cd_bill
      ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN customer_demographics cd_ship
      ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    GROUP BY d_ws.d_year
  )
SELECT
  cr.year,
  cr.ship_contract,
  cr.return_reason,
  cr.gender,
  cr.total_return_net_loss,
  cr.return_cnt,
  ss.total_store_profit,
  ss.store_cnt,
  ws.total_web_profit,
  ws.web_cnt
FROM cr_agg cr
LEFT JOIN ss_agg ss
  ON cr.year = ss.year
LEFT JOIN ws_agg ws
  ON cr.year = ws.year
ORDER BY cr.year DESC, cr.total_return_net_loss DESC
LIMIT 100
