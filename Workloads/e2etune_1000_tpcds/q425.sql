SELECT ca.ca_address_id,
       s.cc_city,
       ret.r_reason_desc,
       s.total_sales_profit,
       ret.total_return_loss,
       (s.total_sales_profit - ret.total_return_loss) AS net_profit_after_returns
FROM (
    SELECT cs.cs_bill_addr_sk AS address_sk,
           cc.cc_city,
           SUM(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_class = 'large'
      AND cs.cs_sold_date_sk BETWEEN 20000101 AND 20001231
    GROUP BY cs.cs_bill_addr_sk, cc.cc_city
) s
JOIN (
    SELECT sr.sr_addr_sk AS address_sk,
           r.r_reason_desc,
           SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_returned_date_sk BETWEEN 20000101 AND 20001231
    GROUP BY sr.sr_addr_sk, r.r_reason_desc
) ret ON s.address_sk = ret.address_sk
JOIN customer_address ca ON s.address_sk = ca.ca_address_sk
WHERE s.total_sales_profit > 100000
  AND ret.total_return_loss > 0
ORDER BY net_profit_after_returns DESC
LIMIT 50
