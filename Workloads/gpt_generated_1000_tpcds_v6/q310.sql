WITH high_fee AS (
   SELECT
       r.r_reason_desc,
       SUM(wr.wr_net_loss) AS total_net_loss,
       COUNT(*) AS return_cnt
   FROM web_returns wr
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   WHERE wr.wr_fee > (SELECT AVG(wr_fee) FROM web_returns)
     AND r.r_reason_desc LIKE '%Did not like%'
     AND EXISTS (
         SELECT 1 FROM reason r2
         WHERE r2.r_reason_sk = wr.wr_reason_sk
           AND r2.r_reason_id = 'AAAAAAAABAAAAAAA'
     )
   GROUP BY r.r_reason_desc
),
multiple_qty AS (
   SELECT
       r.r_reason_desc,
       SUM(wr.wr_net_loss) AS total_net_loss,
       COUNT(*) AS return_cnt
   FROM web_returns wr
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   WHERE wr.wr_return_quantity > 1
     AND r.r_reason_desc LIKE '%Wrong size%'
     AND r.r_reason_id IN (
         SELECT r3.r_reason_id FROM reason r3 WHERE r3.r_reason_desc LIKE '%size%'
     )
   GROUP BY r.r_reason_desc
)
SELECT r_reason_desc, total_net_loss, return_cnt
FROM high_fee
UNION ALL
SELECT r_reason_desc, total_net_loss, return_cnt
FROM multiple_qty
ORDER BY total_net_loss DESC
LIMIT 100
