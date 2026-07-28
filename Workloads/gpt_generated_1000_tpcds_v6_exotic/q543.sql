WITH
  store_side AS (
    SELECT
      p.p_promo_name      AS category,
      s.s_state           AS region,
      ss.ss_net_profit    AS metric
    FROM
      tpcds.store_sales ss
      JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
      JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
      JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
      JOIN tpcds.time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
      JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
      JOIN tpcds.store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    WHERE
      s.s_state = 'CA'
      AND i.i_current_price > 20
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND hd.hd_vehicle_count > 1
      AND sr.sr_return_quantity > 0
  ),
  catalog_side AS (
    SELECT
      cc.cc_name          AS category,
      cc.cc_state         AS region,
      cr.cr_net_loss      AS metric
    FROM
      tpcds.catalog_returns cr
      JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
      JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
      JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN tpcds.time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
      JOIN tpcds.household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE
      cc.cc_state = 'TX'
      AND i.i_current_price > 20
      AND sm.sm_type = 'AIR'
      AND t.t_hour BETWEEN 9 AND 17
      AND hd.hd_vehicle_count > 1
      AND cr.cr_return_amount > 100
  )
SELECT
  category,
  region,
  SUM(metric) AS total_metric
FROM (
  SELECT * FROM store_side
  UNION ALL
  SELECT * FROM catalog_side
) AS unified
GROUP BY
  category,
  region
HAVING
  SUM(metric) > 1000
ORDER BY
  total_metric DESC
LIMIT 100
