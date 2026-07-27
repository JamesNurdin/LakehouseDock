WITH
store_sales_summary AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        cd.cd_gender AS gender,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        CASE
            WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High'
            WHEN SUM(ss.ss_net_profit) > 5000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE s.s_store_name LIKE '%Store%'
    GROUP BY s.s_store_id, s.s_store_name, cd.cd_gender
),
catalog_sales_summary AS (
    SELECT
        sm.sm_ship_mode_id AS mode_id,
        sm.sm_code AS mode_code,
        CASE
            WHEN regexp_like(sm.sm_code, '^A') THEN 'Air'
            WHEN regexp_like(sm.sm_code, '^B') THEN 'Bike'
            ELSE 'Other'
        END AS mode_category,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        CASE
            WHEN SUM(cs.cs_net_profit) > 20000 THEN 'High'
            WHEN SUM(cs.cs_net_profit) > 10000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        regexp_extract(sm.sm_ship_mode_id, '[A-Z]+') AS mode_alpha
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_contract LIKE '%a%'
    GROUP BY sm.sm_ship_mode_id,
        sm.sm_code,
        CASE
            WHEN regexp_like(sm.sm_code, '^A') THEN 'Air'
            WHEN regexp_like(sm.sm_code, '^B') THEN 'Bike'
            ELSE 'Other'
        END,
        regexp_extract(sm.sm_ship_mode_id, '[A-Z]+')
)

SELECT DISTINCT
    store_id AS id,
    store_name AS name,
    gender AS segment,
    total_net_profit,
    profit_category,
    'Store' AS source
FROM store_sales_summary

UNION ALL

SELECT
    mode_id AS id,
    mode_code AS name,
    mode_category AS segment,
    total_net_profit,
    profit_category,
    'ShipMode' AS source
FROM catalog_sales_summary

ORDER BY total_net_profit DESC
