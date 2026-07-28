WITH base AS (
   SELECT
     r.r_reason_desc,
     hd.hd_buy_potential,
     SUM(wr.wr_net_loss) AS total_net_loss,
     COUNT(*) AS return_cnt,
     SUM(wr.wr_fee) AS total_fee,
     CASE WHEN SUM(wr.wr_net_loss) > 100 THEN 'High' ELSE 'Low' END AS loss_category
   FROM web_returns wr
   JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
   JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   WHERE hd.hd_vehicle_count > 0
     AND r.r_reason_desc LIKE '%model%'
     AND wr.wr_fee > 20
   GROUP BY r.r_reason_desc, hd.hd_buy_potential
)
SELECT
  r_reason_desc,
  hd_buy_potential,
  total_net_loss,
  return_cnt,
  total_fee,
  loss_category,
  RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank,
  SUM(total_net_loss) OVER (PARTITION BY loss_category) AS category_net_loss_sum
FROM base
ORDER BY total_net_loss DESC, r_reason_desc
LIMIT 100
