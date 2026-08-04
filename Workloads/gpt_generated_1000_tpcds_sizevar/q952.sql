WITH returns_orders AS (
       SELECT cr_order_number
       FROM catalog_returns
       EXCEPT
       SELECT cs_order_number
       FROM catalog_sales
   ),
   joined_data AS (
       SELECT
           cr.cr_order_number,
           cr.cr_return_amount,
           cr.cr_net_loss,
           cr.cr_reason_sk,
           r.r_reason_desc,
           ca.ca_city,
           ca.ca_state,
           d.d_month_seq,
           d.d_year,
           CASE WHEN d.d_month_seq % 2 = 0 THEN 'Even' ELSE 'Odd' END AS month_parity,
           CONCAT(ca.ca_city, ', ', ca.ca_state) AS location,
           SUBSTRING(ca.ca_city, 1, 3) AS city_prefix
       FROM catalog_returns cr
       JOIN catalog_sales cs
         ON cr.cr_order_number = cs.cs_order_number
       JOIN reason r
         ON cr.cr_reason_sk = r.r_reason_sk
       JOIN customer_address ca
         ON cr.cr_refunded_addr_sk = ca.ca_address_sk
       JOIN date_dim d
         ON cr.cr_returned_date_sk = d.d_date_sk
       WHERE REGEXP_LIKE(r.r_reason_desc, '(?i)defect|damage')
         AND ca.ca_city LIKE 'A%'
   )
SELECT
    jd.r_reason_desc,
    jd.location,
    jd.month_parity,
    COUNT(DISTINCT jd.cr_order_number) AS distinct_orders,
    SUM(jd.cr_net_loss) AS total_net_loss,
    AVG(jd.cr_return_amount) AS avg_return_amount,
    (SELECT SUM(cr2.cr_return_amount)
       FROM catalog_returns cr2
       WHERE cr2.cr_reason_sk = jd.cr_reason_sk) AS total_return_amount_by_reason,
    CASE WHEN MAX(CASE WHEN EXISTS (SELECT 1 FROM returns_orders ro WHERE ro.cr_order_number = jd.cr_order_number) THEN 1 ELSE 0 END) = 1
         THEN 'Orphan Return'
         ELSE 'Matched Sale'
    END AS return_status
FROM joined_data jd
GROUP BY
    jd.r_reason_desc,
    jd.location,
    jd.month_parity,
    jd.cr_reason_sk
ORDER BY total_net_loss DESC
LIMIT 100
