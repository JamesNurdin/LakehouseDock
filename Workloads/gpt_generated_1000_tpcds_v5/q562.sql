WITH store_agg AS (
   SELECT
       r.r_reason_desc,
       SUM(sr.sr_net_loss) AS total_net_loss,
       COUNT(*) AS cnt_returns,
       CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'high' ELSE 'low' END AS loss_category
   FROM store_returns sr
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE sr.sr_store_credit > 100
   GROUP BY r.r_reason_desc
),
web_agg AS (
   SELECT
       r.r_reason_desc,
       SUM(wr.wr_net_loss) AS total_net_loss,
       COUNT(*) AS cnt_returns,
       CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'high' ELSE 'low' END AS loss_category
   FROM web_returns wr
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   WHERE wr.wr_refunded_cash < 500
   GROUP BY r.r_reason_desc
)
SELECT
    'store' AS source,
    r_reason_desc,
    total_net_loss,
    cnt_returns,
    loss_category
FROM store_agg
UNION ALL
SELECT
    'web' AS source,
    r_reason_desc,
    total_net_loss,
    cnt_returns,
    loss_category
FROM web_agg
ORDER BY total_net_loss DESC
LIMIT 100
