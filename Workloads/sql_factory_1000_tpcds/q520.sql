WITH profit_by_birth AS (
    SELECT
        c.c_birth_year AS birth_year,
        c.c_birth_country AS birth_country,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        MAX(ws.ws_net_paid) AS max_paid
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_ship_mode_sk IN (1,2,3) -- focus on specific ship modes
    GROUP BY c.c_birth_year, c.c_birth_country
),
inventory_by_birth_warehouse AS (
    SELECT
        c.c_birth_year AS birth_year,
        c.c_birth_country AS birth_country,
        i.inv_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS warehouse_stock,
        SUM(i.inv_quantity_on_hand) * 0.8 AS adjusted_stock
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN inventory i ON ws.ws_item_sk = i.inv_item_sk
    GROUP BY c.c_birth_year, c.c_birth_country, i.inv_warehouse_sk
),
best_warehouse AS (
    SELECT
        birth_year,
        birth_country,
        inv_warehouse_sk,
        warehouse_stock,
        ROW_NUMBER() OVER (PARTITION BY birth_year, birth_country ORDER BY adjusted_stock DESC) AS rn
    FROM inventory_by_birth_warehouse
)
SELECT
    pb.birth_year,
    pb.birth_country,
    pb.total_profit,
    pb.avg_discount,
    pb.max_paid,
    bw.warehouse_stock AS best_stock,
    w.w_warehouse_name AS best_warehouse_name,
    RANK() OVER (ORDER BY pb.total_profit DESC) AS profit_rank,
    SUM(pb.total_profit) OVER (PARTITION BY pb.birth_country ORDER BY pb.total_profit ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_by_country,
    CASE WHEN pb.total_profit > 180000 THEN 'Platinum' WHEN pb.total_profit > 90000 THEN 'Gold' WHEN pb.total_profit > 30000 THEN 'Silver' ELSE 'Bronze' END AS profit_tier,
    CASE WHEN bw.warehouse_stock < pb.total_profit / 8 THEN 'Potential Shortage' ELSE 'Adequate Inventory' END AS inventory_status
FROM profit_by_birth pb
LEFT JOIN best_warehouse bw ON pb.birth_year = bw.birth_year AND pb.birth_country = bw.birth_country AND bw.rn = 1
LEFT JOIN warehouse w ON bw.inv_warehouse_sk = w.w_warehouse_sk
ORDER BY profit_rank
