WITH profit_by_birth AS (
    SELECT
        c.c_birth_year AS birth_year,
        c.c_birth_country AS birth_country,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_birth_year, c.c_birth_country
),
inventory_by_birth_warehouse AS (
    SELECT
        c.c_birth_year AS birth_year,
        c.c_birth_country AS birth_country,
        i.inv_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS warehouse_stock
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN inventory i
        ON ws.ws_item_sk = i.inv_item_sk
    GROUP BY c.c_birth_year, c.c_birth_country, i.inv_warehouse_sk
),
top_warehouse_per_birth AS (
    SELECT
        birth_year,
        birth_country,
        inv_warehouse_sk,
        warehouse_stock,
        ROW_NUMBER() OVER (PARTITION BY birth_year, birth_country ORDER BY warehouse_stock DESC) AS rn
    FROM inventory_by_birth_warehouse
)
SELECT
    pb.birth_year,
    pb.birth_country,
    pb.total_profit,
    pb.avg_discount,
    COALESCE(twb.warehouse_stock, 0) AS total_inventory,
    w.w_warehouse_name AS top_warehouse_name,
    DENSE_RANK() OVER (ORDER BY pb.total_profit DESC) AS profit_rank,
    SUM(pb.total_profit) OVER (PARTITION BY pb.birth_year ORDER BY pb.total_profit ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
    CASE
        WHEN pb.total_profit > 100000 THEN 'Platinum'
        WHEN pb.total_profit > 50000 THEN 'Gold'
        WHEN pb.total_profit > 10000 THEN 'Silver'
        ELSE 'Bronze'
    END AS profit_tier,
    CASE
        WHEN COALESCE(twb.warehouse_stock, 0) < pb.total_profit / 10 THEN 'Potential Shortage'
        ELSE 'Adequate Inventory'
    END AS inventory_status
FROM profit_by_birth pb
LEFT JOIN top_warehouse_per_birth twb
    ON pb.birth_year = twb.birth_year
    AND pb.birth_country = twb.birth_country
    AND twb.rn = 1
LEFT JOIN warehouse w
    ON twb.inv_warehouse_sk = w.w_warehouse_sk
ORDER BY profit_rank
