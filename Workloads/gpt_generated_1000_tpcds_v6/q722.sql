WITH price_reasons AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE lower(r_reason_desc) LIKE '%price%'
)
SELECT reason_desc,
       total_loss,
       return_source,
       state_flag
FROM (
    SELECT r.r_reason_desc AS reason_desc,
           SUM(sr.sr_net_loss) AS total_loss,
           'store' AS return_source,
           CASE WHEN ca.ca_state = 'CA' THEN 'CA' ELSE 'Other' END AS state_flag
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN price_reasons pr ON r.r_reason_sk = pr.r_reason_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM customer c2
          WHERE c2.c_customer_sk = sr.sr_customer_sk
            AND c2.c_preferred_cust_flag = 'Y'
      )
    GROUP BY r.r_reason_desc, ca.ca_state
) 
UNION ALL
SELECT reason_desc,
       total_loss,
       return_source,
       state_flag
FROM (
    SELECT r.r_reason_desc AS reason_desc,
           SUM(cr.cr_net_loss) AS total_loss,
           'catalog' AS return_source,
           CASE WHEN w.w_state = 'CA' THEN 'CA' ELSE 'Other' END AS state_flag
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN price_reasons pr ON r.r_reason_sk = pr.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND w.w_warehouse_sq_ft > 500000
    GROUP BY r.r_reason_desc, w.w_state
) AS combined
ORDER BY total_loss DESC
LIMIT 100
