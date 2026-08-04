WITH
  base_join AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cc.cc_name,
      sm.sm_ship_mode_id,
      w.w_warehouse_name,
      td.t_hour,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ib.ib_upper_bound,
      ws.ws_net_paid,
      site.web_name,
      sr.sr_net_loss
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
    WHERE cc.cc_state = 'CA'
      AND cr.cr_return_amount > 200
      AND td.t_hour BETWEEN 10 AND 16
      AND ib.ib_upper_bound >= 150000
      AND ws.ws_quantity >= 4
  ),
  high_net_paid AS (
    SELECT ws.ws_order_number AS order_id
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_net_paid > 5000
      AND td.t_hour >= 12
  ),
  returned_orders AS (
    SELECT cr.cr_order_number AS order_id
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 2
      AND cr.cr_return_amount > 300
  ),
  intersect_orders AS (
    SELECT order_id FROM high_net_paid
    INTERSECT
    SELECT order_id FROM returned_orders
  ),
  except_orders AS (
    SELECT order_id FROM high_net_paid
    EXCEPT
    SELECT order_id FROM returned_orders
  ),
  cross_income AS (
    SELECT hd.hd_demo_sk, ib.ib_income_band_sk
    FROM household_demographics hd
    CROSS JOIN (SELECT ib_income_band_sk FROM income_band WHERE ib_upper_bound > 120000) ib
  ),
  lateral_agg AS (
    SELECT
      ws.ws_order_number,
      la.max_return_amount
    FROM web_sales ws
    LEFT JOIN LATERAL (
        SELECT MAX(cr.cr_return_amount) AS max_return_amount
        FROM catalog_returns cr
        WHERE cr.cr_order_number = ws.ws_order_number
    ) la ON TRUE
    WHERE ws.ws_net_paid > 0
  )
SELECT DISTINCT
  bj.cc_name,
  bj.sm_ship_mode_id,
  bj.w_warehouse_name,
  bj.t_hour,
  bj.cd_gender,
  bj.hd_income_band_sk,
  bj.ib_upper_bound,
  bj.ws_net_paid,
  bj.web_name,
  bj.sr_net_loss,
  la.max_return_amount
FROM base_join bj
JOIN intersect_orders io ON bj.cr_order_number = io.order_id
LEFT JOIN lateral_agg la ON bj.cr_order_number = la.ws_order_number
WHERE bj.sr_net_loss < 1000
GROUP BY
  bj.cc_name,
  bj.sm_ship_mode_id,
  bj.w_warehouse_name,
  bj.t_hour,
  bj.cd_gender,
  bj.hd_income_band_sk,
  bj.ib_upper_bound,
  bj.ws_net_paid,
  bj.web_name,
  bj.sr_net_loss,
  la.max_return_amount
ORDER BY bj.ws_net_paid DESC
LIMIT 100
