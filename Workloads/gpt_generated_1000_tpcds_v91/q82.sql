WITH excluded_warehouses AS (
    SELECT DISTINCT w.w_warehouse_sk
    FROM warehouse w
    WHERE w.w_country = 'United States'
    EXCEPT
    SELECT ws.ws_warehouse_sk
    FROM web_sales ws
    WHERE ws.ws_ext_wholesale_cost > 2000
),
base AS (
    SELECT
        d.d_year,
        d.d_date_sk,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_country,
        w.w_street_type,
        ss.ss_wholesale_cost,
        ss.ss_net_profit,
        ss.ss_net_paid,
        ws.ws_ext_wholesale_cost,
        ws.ws_net_profit,
        ws.ws_net_paid,
        inv.inv_quantity_on_hand,
        site.web_name,
        site.web_tax_percentage
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    WHERE d.d_year = 2001
      AND w.w_country = 'United States'
      AND w.w_street_type IN ('Drive', 'Road')
      AND ss.ss_wholesale_cost > 50
      AND ws.ws_ext_wholesale_cost > 1000
      AND inv.inv_quantity_on_hand > 0
      AND site.web_tax_percentage > 0.05
      AND w.w_warehouse_sk IN (SELECT w_warehouse_sk FROM excluded_warehouses)
),
agg AS (
    SELECT
        base.d_year,
        base.w_warehouse_name,
        base.web_name,
        SUM(base.ss_net_profit + base.ws_net_profit) AS total_net_profit,
        SUM(base.ss_net_paid + base.ws_net_paid) AS total_net_paid,
        SUM(base.inv_quantity_on_hand) AS total_inventory_qty,
        SUM(lateral.total_inventory_qty) AS total_inventory_qty_lateral
    FROM base
    CROSS JOIN LATERAL (
        SELECT SUM(inv2.inv_quantity_on_hand) AS total_inventory_qty
        FROM inventory inv2
        WHERE inv2.inv_warehouse_sk = base.w_warehouse_sk
    ) AS lateral
    GROUP BY CUBE(base.d_year, base.w_warehouse_name, base.web_name)
)
SELECT
    d_year,
    w_warehouse_name,
    web_name,
    total_inventory_qty,
    total_inventory_qty_lateral,
    total_net_paid,
    total_net_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank,
    CASE
        WHEN total_net_profit >= 200000 THEN 'Very High'
        WHEN total_net_profit >= 100000 THEN 'High'
        WHEN total_net_profit >= 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM agg
WHERE total_inventory_qty > 0
ORDER BY d_year DESC, profit_rank
LIMIT 100
