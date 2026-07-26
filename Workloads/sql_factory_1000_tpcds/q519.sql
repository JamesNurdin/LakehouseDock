WITH profit_by_birth AS (
    SELECT
        c.c_birth_year AS birth_year,
        c.c_birth_country AS birth_country,
        SUM(ws.ws_net_profit) AS total_profit,
        MIN(ws.ws_ext_discount_amt) AS min_discount,
        MAX(ws.ws_ext_discount_amt) AS max_discount
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk >= 2451545 -- filter to recent sales
    GROUP BY c.c_birth_year, c.c_birth_country
),
inventory_by_birth_warehouse AS (
    SELECT
        c.c_birth_year AS birth_year,
        c.c_birth_country AS birth_country,
        i.inv_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS warehouse_stock,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN inventory i ON ws.ws_item_sk = i.inv_item_sk
    GROUP BY c.c_birth_year, c.c_birth_country, i.inv_warehouse_sk
),
ranked_warehouses AS (
    SELECT
        birth_year,
        birth_country,
        inv_warehouse_sk,
        warehouse_stock,
        DENSE_RANK() OVER (PARTITION BY birth_year, birth_country ORDER BY warehouse_stock DESC) AS dr
    FROM inventory_by_birth_warehouse
)
SELECT
    pb.birth_year,
    pb.birth_country,
    pb.total_profit,
    pb.min_discount,
    pb.max_discount,
    rw.warehouse_stock,
    w.w_warehouse_name,
    ROW_NUMBER() OVER (ORDER BY pb.total_profit DESC) AS profit_rank,
    SUM(pb.total_profit) OVER (PARTITION BY pb.birth_country ORDER BY pb.total_profit ROWS UNBOUNDED PRECEDING) AS cumulative_profit_by_country,
    CASE WHEN rw.dr = 1 THEN 'Top Warehouse' ELSE 'Other Warehouse' END AS warehouse_category,
    CASE WHEN pb.total_profit > 200000 THEN 'Elite' WHEN pb.total_profit > 80000 THEN 'Premium' ELSE 'Standard' END AS profit_segment
FROM profit_by_birth pb
LEFT JOIN ranked_warehouses rw ON pb.birth_year = rw.birth_year AND pb.birth_country = rw.birth_country AND rw.dr = 1
LEFT JOIN warehouse w ON rw.inv_warehouse_sk = w.w_warehouse_sk
ORDER BY profit_rank DESC
