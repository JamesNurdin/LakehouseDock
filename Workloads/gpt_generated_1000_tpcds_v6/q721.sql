WITH store_ret AS (
  SELECT
    hd.hd_buy_potential,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    'store' AS source
  FROM store_returns sr
  JOIN store_sales ss
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE sr.sr_return_amt > 100
    AND hd.hd_vehicle_count >= 0
  GROUP BY hd.hd_buy_potential
),
catalog_ret AS (
  SELECT
    hd.hd_buy_potential,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    'catalog' AS source
  FROM catalog_returns cr
  JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE cr.cr_return_amount > 100
    AND hd.hd_dep_count <= 5
  GROUP BY hd.hd_buy_potential
)
SELECT *
FROM (
  SELECT * FROM store_ret
  UNION ALL
  SELECT * FROM catalog_ret
) t
ORDER BY total_net_loss DESC
LIMIT 100
