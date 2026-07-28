WITH high_loss_returns AS (
   SELECT cr.cr_returned_date_sk AS return_date_sk,
          td.t_hour AS hour,
          cr.cr_net_loss AS net_loss,
          r.r_reason_desc AS reason_desc,
          cr.cr_order_number AS order_number
   FROM catalog_returns cr
   JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE cr.cr_net_loss > 1000
     AND r.r_reason_desc IN (
         SELECT r2.r_reason_desc
         FROM reason r2
         WHERE r2.r_reason_desc LIKE 'Customer%'
     )
)
SELECT hr.return_date_sk,
       hr.hour,
       hr.net_loss,
       hr.reason_desc
FROM high_loss_returns hr
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs
    WHERE cs.cs_order_number = hr.order_number
      AND cs.cs_net_profit > 0
)
UNION ALL
SELECT wr.wr_returned_date_sk AS return_date_sk,
       td.t_hour AS hour,
       wr.wr_net_loss AS net_loss,
       r.r_reason_desc AS reason_desc
FROM web_returns wr
JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE wr.wr_net_loss > 1000
  AND r.r_reason_desc NOT IN (
      SELECT r2.r_reason_desc
      FROM reason r2
      WHERE r2.r_reason_desc LIKE 'Customer%'
  )
ORDER BY net_loss DESC
LIMIT 100
