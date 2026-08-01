/*
Goal: Identify the top cities (up to 100) where the combined net profit from store and web sales is highest, but only for cities that do NOT host any warehouse. The query aggregates profit and transaction counts per city from both sales channels, unions the results, re‑aggregates, applies an anti‑join to exclude cities with warehouses, and orders by total net profit.
*/
WITH store_city_profit AS (
    SELECT
        ca.ca_city AS city,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(*) AS txn_count
    FROM tpcds.store_sales ss
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_list_price > 30
      AND ss.ss_ext_tax > 0
    GROUP BY ca.ca_city
),
web_city_profit AS (
    SELECT
        ca.ca_city AS city,
        SUM(ws.ws_net_profit) AS net_profit,
        COUNT(*) AS txn_count
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_list_price > 30
      AND w.w_country = 'United States'
    GROUP BY ca.ca_city
),
combined AS (
    SELECT city, net_profit, txn_count FROM store_city_profit
    UNION ALL
    SELECT city, net_profit, txn_count FROM web_city_profit
),
aggregated AS (
    SELECT
        city,
        SUM(net_profit) AS total_net_profit,
        SUM(txn_count) AS total_txn
    FROM combined
    GROUP BY city
)
SELECT DISTINCT
    a.city,
    a.total_net_profit,
    a.total_txn
FROM aggregated a
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.warehouse w2
    WHERE w2.w_city = a.city
)
ORDER BY a.total_net_profit DESC
LIMIT 100
