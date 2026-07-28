WITH combined_metrics AS (
    SELECT ss.ss_store_sk AS store_sk,
           ss.ss_sold_date_sk AS date_sk,
           SUM(ss.ss_net_profit) AS metric_value,
           'sales' AS metric_type,
           ca.ca_city AS city,
           ca.ca_suite_number AS suite_number
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_suite_number, '^Suite [0-9]+$')
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ca.ca_city, ca.ca_suite_number

    UNION ALL

    SELECT sr.sr_store_sk AS store_sk,
           sr.sr_returned_date_sk AS date_sk,
           -SUM(sr.sr_net_loss) AS metric_value,
           'return' AS metric_type,
           ca.ca_city AS city,
           ca.ca_suite_number AS suite_number
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city LIKE '%ville%'
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk, ca.ca_city, ca.ca_suite_number
)
SELECT cm.store_sk,
       cm.date_sk,
       cm.metric_type,
       cm.metric_value,
       CASE
           WHEN cm.metric_value > 10000 THEN 'High'
           WHEN cm.metric_value > 0 THEN 'Medium'
           ELSE 'Low'
       END AS profit_category,
       cm.city,
       regexp_extract(cm.suite_number, '(\\d+)', 1) AS suite_number_digits,
       (SELECT COUNT(DISTINCT cs2.cs_bill_customer_sk)
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = cm.date_sk
          AND cs2.cs_item_sk IN (
              SELECT cr.cr_item_sk
              FROM catalog_returns cr
              WHERE cr.cr_order_number = cs2.cs_order_number
          )
       ) AS related_customer_count
FROM combined_metrics cm
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    JOIN reason r ON sr2.sr_reason_sk = r.r_reason_sk
    WHERE sr2.sr_store_sk = cm.store_sk
      AND regexp_like(r.r_reason_desc, '.*damage.*')
)
ORDER BY cm.metric_value DESC
LIMIT 100
