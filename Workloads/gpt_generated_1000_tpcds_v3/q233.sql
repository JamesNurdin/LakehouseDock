/* Goal: Calculate total net profit by warehouse and ship mode for customers whose address suite starts with "Suite A" and street type matches common road types, while also showing the overall average profit across all catalog and web sales. */
WITH filtered_customers AS (
    SELECT
        ca_address_sk,
        ca_city,
        ca_state,
        ca_suite_number,
        ca_street_type,
        ca_street_name,
        regexp_extract(ca_suite_number, 'Suite ([A-Z0-9]+)', 1) AS suite_code,
        CONCAT(ca_city, ', ', ca_state) AS city_state
    FROM
        customer_address
    WHERE
        ca_suite_number LIKE 'Suite A%' -- suite starts with A
        AND regexp_like(ca_street_type, '(Way|Road|Rd\\.|Dr\\.)')
)
SELECT
    w.w_warehouse_name,
    sm.sm_type,
    (SUM(COALESCE(cs.cs_net_profit, 0)) + SUM(COALESCE(ws.ws_net_profit, 0))) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_order_count,
    (SELECT AVG(net_profit)
     FROM (
         SELECT cs2.cs_net_profit AS net_profit FROM catalog_sales cs2
         UNION ALL
         SELECT ws2.ws_net_profit FROM web_sales ws2
     ) AS all_profits) AS avg_profit_all
FROM
    filtered_customers fc
    JOIN catalog_sales cs
        ON cs.cs_bill_addr_sk = fc.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_addr_sk = fc.ca_address_sk
        AND ws.ws_order_number IN (
            SELECT cs_sub.cs_order_number
            FROM catalog_sales cs_sub
            WHERE cs_sub.cs_quantity > 5
        )
WHERE
    sm.sm_code LIKE 'S%' -- ship mode code starts with S
    AND regexp_like(fc.ca_city, '^New')
GROUP BY
    w.w_warehouse_name,
    sm.sm_type
ORDER BY
    total_net_profit DESC
LIMIT 100
