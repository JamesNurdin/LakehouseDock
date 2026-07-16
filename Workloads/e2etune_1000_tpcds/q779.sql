SELECT p.country,
       l.reason,
       p.total_profit,
       l.total_loss,
       (p.total_profit - l.total_loss) AS net_contribution,
       RANK() OVER (ORDER BY (p.total_profit - l.total_loss) DESC) AS rank
FROM (
    SELECT ca.ca_country AS country,
           SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY ca.ca_country
) p
JOIN (
    SELECT ca.ca_country AS country,
           r.r_reason_desc AS reason,
           SUM(ret.net_loss) AS total_loss
    FROM (
        SELECT sr.sr_addr_sk AS addr_sk,
               sr.sr_reason_sk AS reason_sk,
               sr.sr_net_loss AS net_loss,
               sr.sr_returned_date_sk AS date_sk
        FROM store_returns sr
        UNION ALL
        SELECT wr.wr_refunded_addr_sk AS addr_sk,
               wr.wr_reason_sk AS reason_sk,
               wr.wr_net_loss AS net_loss,
               wr.wr_returned_date_sk AS date_sk
        FROM web_returns wr
    ) ret
    JOIN customer_address ca ON ret.addr_sk = ca.ca_address_sk
    JOIN reason r ON ret.reason_sk = r.r_reason_sk
    WHERE ret.date_sk BETWEEN 2450000 AND 2452000
    GROUP BY ca.ca_country, r.r_reason_desc
) l
ON p.country = l.country
WHERE p.total_profit > 10000
  AND (p.total_profit - l.total_loss) > 0
ORDER BY net_contribution DESC
LIMIT 20
