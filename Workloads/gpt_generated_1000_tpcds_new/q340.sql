WITH
  -- Full outer join between Call Center and Ship Mode via order number
  full_cc_sm AS (
    SELECT
      a.cr_order_number,
      a.cc_name,
      b.sm_type
    FROM (
      SELECT cr.cr_order_number, cc.cc_name
      FROM catalog_returns cr
      JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    ) a
    FULL OUTER JOIN (
      SELECT cr.cr_order_number, sm.sm_type
      FROM catalog_returns cr
      JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    ) b
      ON a.cr_order_number = b.cr_order_number
  ),
  -- Order numbers that appear in both catalog and web returns with significant amounts
  order_intersect AS (
    SELECT cr2.cr_order_number
    FROM catalog_returns cr2
    WHERE cr2.cr_return_amount > 200
    INTERSECT
    SELECT wr2.wr_order_number
    FROM web_returns wr2
    WHERE wr2.wr_return_amt > 200
  )
SELECT
  sm.sm_type,
  cd_ws_bill.cd_gender,
  r.r_reason_desc,
  SUM(cr.cr_net_loss)               AS total_return_loss,
  SUM(ws.ws_net_profit)             AS total_sales_profit,
  COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
  ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_net_loss) DESC) AS rn
FROM catalog_returns cr
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd_ref
  ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
  ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN time_dim td1
  ON cr.cr_returned_time_sk = td1.t_time_sk
JOIN web_sales ws
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN customer_demographics cd_ws_bill
  ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN customer_demographics cd_ws_ship
  ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
JOIN store_returns sr
  ON sr.sr_return_time_sk = td1.t_time_sk
JOIN customer_demographics cd_sr
  ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
WHERE cr.cr_order_number IN (SELECT cr_order_number FROM order_intersect)
  AND EXISTS (
        SELECT 1
        FROM full_cc_sm f
        WHERE f.cr_order_number = cr.cr_order_number
          AND f.cc_name IS NOT NULL
          AND f.sm_type IS NOT NULL
      )
GROUP BY sm.sm_type, cd_ws_bill.cd_gender, r.r_reason_desc
ORDER BY total_return_loss DESC
LIMIT 100
