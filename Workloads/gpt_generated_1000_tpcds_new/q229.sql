WITH base_join AS (
   SELECT
       cr.cr_returning_addr_sk,
       cr.cr_refunded_addr_sk,
       cr.cr_reason_sk,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       cr.cr_return_tax,
       cr.cr_return_amt_inc_tax,
       cr.cr_net_loss,
       ca.ca_city,
       ca.ca_gmt_offset,
       r.r_reason_desc
   FROM catalog_returns cr
   FULL OUTER JOIN reason r
       ON cr.cr_reason_sk = r.r_reason_sk
   LEFT JOIN customer_address ca
       ON cr.cr_returning_addr_sk = ca.ca_address_sk
   WHERE cr.cr_return_amount > 10.00
     AND cr.cr_return_quantity BETWEEN 1 AND 10
     AND cr.cr_return_tax < 5.00
     AND ca.ca_gmt_offset BETWEEN -8.00 AND -5.00
     AND r.r_reason_desc IS NOT NULL
     AND ca.ca_city IN ('Maple Grove','Greenville')
     AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_returning_addr_sk = cr.cr_returning_addr_sk
            AND cr2.cr_return_amount > cr.cr_return_amount
     )
),
expanded AS (
   SELECT
       bj.*,
       v AS val
   FROM base_join bj
   CROSS JOIN UNNEST(array[ bj.cr_return_quantity, bj.cr_return_amount]) AS t(v)
),
per_city_reason AS (
   SELECT
       ca_city,
       r_reason_desc,
       SUM(cr_return_amount) AS total_return_amount,
       COUNT(*) AS cnt,
       AVG(cr_return_amount) AS avg_return_amount
   FROM expanded
   GROUP BY ca_city, r_reason_desc
   HAVING SUM(cr_return_amount) > 100.00
)
SELECT
   pcr.ca_city,
   pcr.r_reason_desc,
   pcr.total_return_amount,
   pcr.cnt,
   pcr.avg_return_amount,
   (pcr.total_return_amount / (SELECT MAX(total_return_amount) FROM per_city_reason)) AS pct_of_max
FROM per_city_reason pcr
ORDER BY pcr.total_return_amount DESC
LIMIT 100
