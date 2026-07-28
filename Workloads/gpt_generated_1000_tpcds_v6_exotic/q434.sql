WITH avg_ship_cost AS (
    SELECT avg(cs_ext_ship_cost) AS avg_ship_cost
    FROM catalog_sales
)
SELECT
    ca.ca_city AS city,
    'sales' AS metric,
    sum(cs.cs_net_paid) AS amount,
    (SELECT avg_ship_cost FROM avg_ship_cost) AS avg_ship_cost
FROM catalog_sales cs
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE ca.ca_suite_number = 'Suite 180'
  AND cs.cs_ext_ship_cost > 1000
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN customer_address ca2
          ON sr.sr_addr_sk = ca2.ca_address_sk
        WHERE ca2.ca_city = ca.ca_city
          AND sr.sr_return_ship_cost > 300
    )
GROUP BY ca.ca_city

UNION ALL

SELECT
    ca.ca_city AS city,
    'returns' AS metric,
    sum(sr.sr_return_amt) AS amount,
    (SELECT avg_ship_cost FROM avg_ship_cost) AS avg_ship_cost
FROM store_returns sr
JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
WHERE ca.ca_location_type = 'apartment'
  AND sr.sr_return_ship_cost > 200
  AND ca.ca_city IN (
        SELECT ca3.ca_city
        FROM catalog_sales cs3
        JOIN customer_address ca3
          ON cs3.cs_ship_addr_sk = ca3.ca_address_sk
        WHERE cs3.cs_ext_ship_cost > 800
    )
GROUP BY ca.ca_city

ORDER BY city, metric
LIMIT 100
