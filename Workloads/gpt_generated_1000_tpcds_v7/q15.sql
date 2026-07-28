/*
  Goal: Summarize profit by ship mode contracts for shipments to cities containing 'York' in the year 2002, applying regular‑expression filters on ship‑mode contracts, concatenating city and state, classifying transport type with a CASE expression, and ensuring that at least one high‑value store‑sale exists for the same date and address.
*/
SELECT
    sm.sm_ship_mode_id,
    CASE
        WHEN sm.sm_code = 'AIR' THEN 'Air Transport'
        WHEN sm.sm_code = 'SEA' THEN 'Sea Transport'
        ELSE 'Other'
    END AS transport_type,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
    REGEXP_EXTRACT(sm.sm_contract, '(\\d+)', 1) AS contract_number_part,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_net_profit) AS total_profit,
    ROUND(AVG(cs.cs_net_profit), 2) AS avg_profit
FROM catalog_sales cs
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca
  ON cs.cs_ship_addr_sk = ca.ca_address_sk
JOIN date_dim d
  ON cs.cs_ship_date_sk = d.d_date_sk
WHERE
    REGEXP_LIKE(sm.sm_contract, '^[A-Z].*\\d')               -- contract starts with a capital letter and contains a digit
    AND ca.ca_city LIKE '%York%'                               -- city contains the word York
    AND d.d_year = 2002                                        -- only the year 2002
    AND sm.sm_code IN ('AIR', 'SEA')                           -- focus on air and sea modes
    AND EXISTS (                                               -- at least one qualifying store‑sale
        SELECT 1
        FROM store_sales ss
        WHERE ss.ss_sold_date_sk = d.d_date_sk
          AND ss.ss_addr_sk = ca.ca_address_sk
          AND ss.ss_net_paid > 1000
    )
GROUP BY
    sm.sm_ship_mode_id,
    CASE
        WHEN sm.sm_code = 'AIR' THEN 'Air Transport'
        WHEN sm.sm_code = 'SEA' THEN 'Sea Transport'
        ELSE 'Other'
    END,
    ca.ca_city,
    ca.ca_state,
    REGEXP_EXTRACT(sm.sm_contract, '(\\d+)', 1)
ORDER BY total_profit DESC
LIMIT 100
