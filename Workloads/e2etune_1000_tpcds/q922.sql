SELECT
  p.p_promo_name,
  hd.hd_vehicle_count,
  SUM(ss.ss_net_profit) AS total_net_profit,
  COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_return_loss,
  COALESCE(MAX(cr.cr_net_loss), 0) AS total_catalog_return_loss,
  COALESCE(MAX(wr.wr_net_loss), 0) AS total_web_return_loss,
  SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) - COALESCE(MAX(cr.cr_net_loss), 0) - COALESCE(MAX(wr.wr_net_loss), 0) AS net_contribution,
  AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets
FROM store_sales ss
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
  AND ss.ss_item_sk = sr.sr_item_sk
  AND hd.hd_demo_sk = sr.sr_hdemo_sk
LEFT JOIN (
    SELECT
      cr.cr_refunded_hdemo_sk AS hd_demo_sk,
      SUM(cr.cr_net_loss) AS cr_net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_refunded_hdemo_sk
) cr
  ON hd.hd_demo_sk = cr.hd_demo_sk
LEFT JOIN (
    SELECT
      wr.wr_refunded_hdemo_sk AS hd_demo_sk,
      SUM(wr.wr_net_loss) AS wr_net_loss
    FROM web_returns wr
    GROUP BY wr.wr_refunded_hdemo_sk
) wr
  ON hd.hd_demo_sk = wr.hd_demo_sk
WHERE ss.ss_sold_date_sk BETWEEN 2450800 AND 2451100
  AND p.p_cost > 1000
  AND p.p_channel_email IS NOT NULL
GROUP BY p.p_promo_name, hd.hd_vehicle_count
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY net_contribution DESC
LIMIT 100
