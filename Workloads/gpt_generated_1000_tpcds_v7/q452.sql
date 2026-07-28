WITH store_ret AS (
   SELECT r.r_reason_desc AS reason_desc,
          SUM(sr.sr_return_amt) AS total_return_amt,
          SUM(sr.sr_net_loss) AS total_net_loss,
          'Store' AS channel
   FROM reason r
   JOIN store_returns sr ON sr.sr_reason_sk = r.r_reason_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   WHERE s.s_company_id = 1
     AND s.s_street_name LIKE '%Park%'
   GROUP BY r.r_reason_desc
),
web_ret AS (
   SELECT r.r_reason_desc AS reason_desc,
          SUM(wr.wr_return_amt) AS total_return_amt,
          SUM(wr.wr_net_loss) AS total_net_loss,
          'Web' AS channel
   FROM reason r
   JOIN web_returns wr ON wr.wr_reason_sk = r.r_reason_sk
   WHERE wr.wr_return_quantity > 10
     AND wr.wr_refunded_cash > 500
   GROUP BY r.r_reason_desc
)
SELECT reason_desc,
       total_return_amt,
       total_net_loss,
       channel
FROM (
   SELECT reason_desc, total_return_amt, total_net_loss, channel FROM store_ret
   UNION ALL
   SELECT reason_desc, total_return_amt, total_net_loss, channel FROM web_ret
) AS combined
ORDER BY total_return_amt DESC
