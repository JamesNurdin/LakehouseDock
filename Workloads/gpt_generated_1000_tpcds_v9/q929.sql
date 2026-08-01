WITH
    eligible_warehouses AS (
        SELECT w.w_warehouse_sk
        FROM warehouse w
        WHERE regexp_like(w.w_county, 'County$')
          AND w.w_city LIKE '%town%'
    ),
    even_suite_warehouses AS (
        SELECT w.w_warehouse_sk
        FROM warehouse w
        WHERE w.w_suite_number LIKE 'Suite %'
          AND CAST(regexp_extract(w.w_suite_number, '\\d+') AS integer) % 2 = 0
    ),
    warehouse_intersect AS (
        SELECT w_warehouse_sk
        FROM eligible_warehouses
        INTERSECT
        SELECT w_warehouse_sk
        FROM even_suite_warehouses
    ),
    warehouse_stats AS (
        SELECT
            w.w_warehouse_sk,
            w.w_county,
            CONCAT(w.w_city, ', ', w.w_state) AS location,
            SUM(cs.cs_net_profit) AS total_net_profit,
            COUNT(DISTINCT cs.cs_order_number) AS orders_count,
            (
                SELECT AVG(cs2.cs_net_profit)
                FROM catalog_sales cs2
                WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
            ) AS avg_net_profit_per_warehouse
        FROM catalog_sales cs
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        WHERE w.w_warehouse_sk IN (SELECT w_warehouse_sk FROM warehouse_intersect)
        GROUP BY w.w_warehouse_sk, w.w_county, w.w_city, w.w_state
    ),
    return_stats AS (
        SELECT
            w.w_warehouse_sk,
            SUM(sr.sr_net_loss) AS total_return_loss,
            COUNT(*) AS return_transactions
        FROM store_returns sr
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN catalog_sales cs ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        GROUP BY w.w_warehouse_sk
    ),
    inventory_check AS (
        SELECT i.inv_warehouse_sk
        FROM inventory i
        WHERE i.inv_quantity_on_hand > 5000
        GROUP BY i.inv_warehouse_sk
    )
SELECT
    ws.w_warehouse_sk,
    ws.location,
    ws.w_county,
    ws.total_net_profit,
    ws.avg_net_profit_per_warehouse,
    COALESCE(rs.total_return_loss, 0) AS total_return_loss,
    COALESCE(rs.return_transactions, 0) AS return_transactions,
    CASE WHEN regexp_like(ws.w_county, '^.*County$') THEN 'County' ELSE 'Other' END AS county_type,
    SUBSTR((SELECT w2.w_suite_number FROM warehouse w2 WHERE w2.w_warehouse_sk = ws.w_warehouse_sk), 7) AS suite_number_digits
FROM warehouse_stats ws
LEFT JOIN return_stats rs ON ws.w_warehouse_sk = rs.w_warehouse_sk
WHERE EXISTS (
    SELECT 1 FROM inventory_check ic WHERE ic.inv_warehouse_sk = ws.w_warehouse_sk
)
GROUP BY
    ws.w_warehouse_sk,
    ws.location,
    ws.w_county,
    ws.total_net_profit,
    ws.avg_net_profit_per_warehouse,
    rs.total_return_loss,
    rs.return_transactions,
    ws.w_county
HAVING
    ws.total_net_profit > 1000
    AND COALESCE(rs.total_return_loss, 0) < 5000
ORDER BY
    ws.total_net_profit DESC
LIMIT 50
