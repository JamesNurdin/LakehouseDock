/*
  Goal: Identify how much revenue was returned (catalog_returns) and how much net revenue was earned (web_sales) for ship modes whose identifier matches a specific regex pattern and whose carrier contains the word "Express". The analysis groups results by the ship mode identifier and the first three characters of the contract code, and restricts returns to minutes = 15 and web sales to hour = 19. The final result is ordered by total returned amount descending and limited to the top 100 rows.
*/
WITH filtered_ship AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        sm.sm_contract,
        substring(sm.sm_contract, 1, 3) AS contract_prefix
    FROM ship_mode AS sm
    WHERE regexp_like(sm.sm_ship_mode_id, '^A{5,}C')
      AND sm.sm_carrier LIKE '%Express%'
)
SELECT
    fs.sm_ship_mode_id AS ship_mode_id,
    fs.contract_prefix,
    SUM(agg.return_amount) AS total_return_amount,
    SUM(agg.web_net_paid) AS total_web_net_paid
FROM (
    SELECT
        cr.cr_return_amount AS return_amount,
        CAST(0.0 AS decimal(7,2)) AS web_net_paid,
        cr.cr_ship_mode_sk AS ship_mode_sk
    FROM catalog_returns AS cr
    JOIN filtered_ship AS fs ON cr.cr_ship_mode_sk = fs.sm_ship_mode_sk
    JOIN time_dim AS td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_minute = 15

    UNION ALL

    SELECT
        CAST(0.0 AS decimal(7,2)) AS return_amount,
        ws.ws_net_paid AS web_net_paid,
        ws.ws_ship_mode_sk AS ship_mode_sk
    FROM web_sales AS ws
    JOIN filtered_ship AS fs ON ws.ws_ship_mode_sk = fs.sm_ship_mode_sk
    JOIN time_dim AS td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour = 19
) AS agg
JOIN filtered_ship AS fs ON agg.ship_mode_sk = fs.sm_ship_mode_sk
GROUP BY
    fs.sm_ship_mode_id,
    fs.contract_prefix
ORDER BY
    total_return_amount DESC
LIMIT 100
