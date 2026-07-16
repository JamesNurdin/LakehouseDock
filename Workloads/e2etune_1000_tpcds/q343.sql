WITH agg AS (
    SELECT
        i.inv_warehouse_sk,
        sm.sm_carrier,
        sm.sm_code,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
        SUM(s.ss_quantity) AS total_sales_qty,
        SUM(s.ss_net_paid) AS total_net_paid,
        SUM(s.ss_net_profit) AS total_net_profit,
        AVG(s.ss_ext_discount_amt) AS avg_discount_amt
    FROM inventory i
    JOIN store_sales s
      ON i.inv_date_sk = s.ss_sold_date_sk
     AND i.inv_item_sk = s.ss_item_sk
    JOIN ship_mode sm
      ON sm.sm_carrier = 'UPS'
     AND sm.sm_code = 'AIR'
    WHERE i.inv_date_sk IN (2451046, 2450815, 2450927)
    GROUP BY i.inv_warehouse_sk, sm.sm_carrier, sm.sm_code
    HAVING SUM(s.ss_net_profit) > 0
)
SELECT
    inv_warehouse_sk,
    sm_carrier,
    sm_code,
    total_inventory_qty,
    total_sales_qty,
    total_net_paid,
    total_net_profit,
    avg_discount_amt,
    CASE WHEN total_inventory_qty = 0 THEN NULL ELSE total_net_profit / total_inventory_qty END AS profit_per_inventory_unit,
    RANK() OVER (PARTITION BY sm_carrier ORDER BY CASE WHEN total_inventory_qty = 0 THEN NULL ELSE total_net_profit / total_inventory_qty END DESC) AS profit_rank_by_warehouse
FROM agg
ORDER BY profit_per_inventory_unit DESC
LIMIT 10
