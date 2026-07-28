/* goal: Identify high‑profit shipping modes by combining catalog and web sales, using string filters on city names, and enrich the result with store return loss metrics. */
WITH cat AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode,
        ca.ca_state,
        ca.ca_city,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        REGEXP_EXTRACT(ca.ca_city, '(\\w+)', 1) AS city_prefix
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    WHERE REGEXP_LIKE(ca.ca_city, '^San')
      AND ca.ca_state LIKE 'C%'
    GROUP BY sm.sm_ship_mode_id, ca.ca_state, ca.ca_city
    HAVING SUM(cs.cs_net_profit) > 10000
),
web AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode,
        ca.ca_state,
        ca.ca_city,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        SUBSTRING(ca.ca_city, 1, 3) AS city_prefix
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city LIKE '%Ville'
      AND sm.sm_type = 'AIR'
    GROUP BY sm.sm_ship_mode_id, ca.ca_state, ca.ca_city
    HAVING SUM(ws.ws_net_profit) > 15000
),
combined AS (
    SELECT ship_mode, ca_state, ca_city, total_profit, distinct_orders, city_prefix
    FROM cat
    UNION ALL
    SELECT ship_mode, ca_state, ca_city, total_profit, distinct_orders, city_prefix
    FROM web
)
SELECT
    combined.ship_mode,
    combined.ca_state,
    combined.city_prefix,
    SUM(combined.total_profit) AS agg_profit,
    COUNT(DISTINCT combined.distinct_orders) AS agg_distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY combined.ship_mode ORDER BY SUM(combined.total_profit) DESC) AS profit_rank,
    (
        SELECT AVG(sr.sr_net_loss)
        FROM store_returns sr
        WHERE sr.sr_hdemo_sk = (
            SELECT hd.hd_demo_sk
            FROM household_demographics hd
            WHERE hd.hd_buy_potential LIKE '%1000%'
            LIMIT 1
        )
    ) AS avg_store_loss
FROM combined
WHERE EXISTS (
    SELECT 1
    FROM household_demographics hd
    WHERE hd.hd_demo_sk = (
        SELECT MIN(sr2.sr_hdemo_sk)
        FROM store_returns sr2
    )
      AND hd.hd_buy_potential LIKE '%500%'
)
GROUP BY combined.ship_mode, combined.ca_state, combined.city_prefix
HAVING SUM(combined.total_profit) > 20000
ORDER BY agg_profit DESC
LIMIT 20
