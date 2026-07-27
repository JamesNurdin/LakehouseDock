WITH store_ret AS (
   SELECT r.r_reason_desc,
          sr.sr_returned_date_sk AS return_date,
          sr.sr_net_loss AS net_loss,
          'store' AS channel
   FROM store_returns sr
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   WHERE t.t_hour BETWEEN 9 AND 17
     AND EXISTS (
         SELECT 1
         FROM store_sales ss
         WHERE ss.ss_ticket_number = sr.sr_ticket_number
           AND ss.ss_quantity > 0
     )
),
web_ret AS (
   SELECT r.r_reason_desc,
          wr.wr_returned_date_sk AS return_date,
          wr.wr_net_loss AS net_loss,
          'web' AS channel
   FROM web_returns wr
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
   WHERE t.t_hour BETWEEN 9 AND 17
     AND EXISTS (
         SELECT 1
         FROM web_sales ws
         WHERE ws.ws_order_number = wr.wr_order_number
           AND ws.ws_quantity > 0
     )
)
SELECT
   channel,
   r_reason_desc,
   SUM(net_loss) AS total_net_loss,
   COUNT(*) AS return_count
FROM (
   SELECT * FROM store_ret
   UNION ALL
   SELECT * FROM web_ret
) combined
GROUP BY channel, r_reason_desc
HAVING SUM(net_loss) > (
   SELECT 0.5 * AVG(total_loss)
   FROM (
       SELECT SUM(net_loss) AS total_loss FROM store_ret
       UNION ALL
       SELECT SUM(net_loss) AS total_loss FROM web_ret
   ) agg
)
ORDER BY total_net_loss DESC, channel
