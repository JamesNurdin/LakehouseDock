WITH overall_avg AS (
    SELECT avg(cs2.cs_sales_price) AS overall_avg_sales_price
    FROM catalog_sales cs2
)
SELECT
    sm.sm_ship_mode_id AS ship_mode_id,
    sm.sm_code AS ship_mode_code,
    sm.sm_type AS ship_type,
    CONCAT(sm.sm_ship_mode_id, '-', SUBSTR(sm.sm_contract, 1, 4)) AS mode_contract_key,
    REGEXP_EXTRACT(sm.sm_contract, '([A-Z]+)', 1) AS contract_alpha,
    SUM(cs.cs_sales_price) AS total_sales_price,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    (SELECT overall_avg_sales_price FROM overall_avg) AS overall_avg_sales_price
FROM catalog_sales cs
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_contract LIKE 'A%'
  AND regexp_like(sm.sm_contract, '^[A-Z]{2}[0-9]')
GROUP BY CUBE(sm.sm_ship_mode_id, sm.sm_code, sm.sm_type, sm.sm_contract)
HAVING SUM(cs.cs_sales_price) > (SELECT overall_avg_sales_price FROM overall_avg)
UNION DISTINCT
SELECT
    sm.sm_ship_mode_id AS ship_mode_id,
    sm.sm_code AS ship_mode_code,
    sm.sm_type AS ship_type,
    CONCAT(sm.sm_ship_mode_id, '-', SUBSTR(sm.sm_contract, 1, 4)) AS mode_contract_key,
    REGEXP_EXTRACT(sm.sm_contract, '([A-Z]+)', 1) AS contract_alpha,
    SUM(cs.cs_sales_price) AS total_sales_price,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    (SELECT overall_avg_sales_price FROM overall_avg) AS overall_avg_sales_price
FROM catalog_sales cs
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_code LIKE 'AIR%'
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_ship_mode_sk = cs.cs_ship_mode_sk
          AND cs2.cs_sales_price > 500
      )
GROUP BY CUBE(sm.sm_ship_mode_id, sm.sm_code, sm.sm_type, sm.sm_contract)
ORDER BY total_sales_price DESC
LIMIT 100
