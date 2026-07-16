WITH inv_by_date AS (
    SELECT
        i.inv_item_sk,
        i.inv_warehouse_sk,
        i.inv_quantity_on_hand,
        i.inv_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq
    FROM inventory i
    JOIN date_dim d
        ON i.inv_date_sk = d.d_date_sk
),
call_center_period AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        cc.cc_country,
        cc.cc_company,
        d_open.d_date AS open_date,
        d_close.d_date AS close_date,
        d_open.d_year AS open_year
    FROM call_center cc
    JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close
        ON cc.cc_closed_date_sk = d_close.d_date_sk
    WHERE cc.cc_country = 'United States'
      AND cc.cc_company IN (1, 2, 3)
),
aggregated_inventory AS (
    SELECT
        cp.cc_call_center_id,
        cp.cc_name,
        cp.cc_city,
        cp.cc_state,
        cp.open_year,
        inv.d_year AS inventory_year,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS distinct_warehouses
    FROM call_center_period cp
    CROSS JOIN inv_by_date inv
    WHERE inv.d_date BETWEEN cp.open_date AND cp.close_date
      AND inv.d_year BETWEEN 2015 AND 2020
    GROUP BY cp.cc_call_center_id, cp.cc_name, cp.cc_city, cp.cc_state, cp.open_year, inv.d_year
    HAVING SUM(inv.inv_quantity_on_hand) > 50000
)
SELECT
    ai.cc_call_center_id,
    ai.cc_name,
    ai.cc_city,
    ai.cc_state,
    ai.open_year,
    ai.inventory_year,
    ai.total_inventory_qty,
    ai.distinct_items,
    ai.distinct_warehouses,
    RANK() OVER (PARTITION BY ai.inventory_year ORDER BY ai.total_inventory_qty DESC) AS yearly_inventory_rank
FROM aggregated_inventory ai
ORDER BY ai.inventory_year, yearly_inventory_rank
LIMIT 25
