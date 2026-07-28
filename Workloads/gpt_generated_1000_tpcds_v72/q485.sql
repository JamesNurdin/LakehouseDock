WITH store_loss AS (
   SELECT
      hd.hd_demo_sk,
      SUM(sr.sr_net_loss) AS loss_amount
   FROM store_returns sr
   JOIN household_demographics hd
     ON sr.sr_hdemo_sk = hd.hd_demo_sk
   WHERE sr.sr_returned_date_sk BETWEEN 2451910 AND 2451920
   GROUP BY hd.hd_demo_sk
),
catalog_loss AS (
   SELECT
      hd.hd_demo_sk,
      SUM(cr.cr_net_loss) AS loss_amount
   FROM catalog_returns cr
   JOIN household_demographics hd
     ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE cr.cr_returned_date_sk BETWEEN 2451910 AND 2451920
   GROUP BY hd.hd_demo_sk
)
SELECT
   combined.hd_demo_sk,
   SUM(combined.loss_amount) AS total_loss
FROM (
   SELECT DISTINCT hd_demo_sk, loss_amount FROM store_loss
   UNION ALL
   SELECT DISTINCT hd_demo_sk, loss_amount FROM catalog_loss
) AS combined
GROUP BY combined.hd_demo_sk
ORDER BY total_loss DESC
LIMIT 100
