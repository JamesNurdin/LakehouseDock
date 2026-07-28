WITH refunded AS (
   SELECT ca.ca_county AS county,
          SUM(cr.cr_return_amount) AS metric,
          'refund_amount' AS metric_type
   FROM catalog_returns cr
   JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   WHERE ca.ca_county = 'Washington County'
     AND cr.cr_store_credit > 20
   GROUP BY ca.ca_county
),
returning AS (
   SELECT ca.ca_county AS county,
          COUNT(DISTINCT cr.cr_order_number) AS metric,
          'order_count' AS metric_type
   FROM catalog_returns cr
   JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
   WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        JOIN customer_address ca2 ON cr2.cr_refunded_addr_sk = ca2.ca_address_sk
        WHERE ca2.ca_county = ca.ca_county
          AND cr2.cr_reversed_charge > 500
   )
   GROUP BY ca.ca_county
)
SELECT DISTINCT county, metric, metric_type
FROM (
   SELECT county, metric, metric_type FROM refunded
   UNION ALL
   SELECT county, metric, metric_type FROM returning
) AS combined
ORDER BY county, metric_type
LIMIT 100
