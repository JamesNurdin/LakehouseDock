WITH store_data AS (
   SELECT
       r.r_reason_desc AS reason_desc,
       ca.ca_city AS city,
       sr.sr_net_loss AS net_loss,
       1 AS return_cnt
   FROM store_returns sr
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE r.r_reason_desc LIKE '%size%'
),
web_data AS (
   SELECT
       r.r_reason_desc AS reason_desc,
       ca.ca_city AS city,
       wr.wr_net_loss AS net_loss,
       1 AS return_cnt
   FROM web_returns wr
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
   WHERE ca.ca_city IN ('Oakland', 'Fairview')
)
SELECT
   reason_desc,
   city,
   SUM(net_loss) AS total_net_loss,
   SUM(return_cnt) AS total_returns
FROM (
   SELECT * FROM store_data
   UNION ALL
   SELECT * FROM web_data
) AS combined
GROUP BY reason_desc, city
ORDER BY total_net_loss DESC
LIMIT 20
