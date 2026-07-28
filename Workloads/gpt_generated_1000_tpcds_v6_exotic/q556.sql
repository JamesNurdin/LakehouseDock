WITH daily_inventory AS (
   SELECT
       i.inv_date_sk,
       i.inv_warehouse_sk,
       i.inv_item_sk,
       i.inv_quantity_on_hand,
       d.d_date,
       d.d_year,
       d.d_quarter_seq,
       d.d_month_seq,
       w.w_warehouse_name,
       w.w_warehouse_sq_ft,
       w.w_state
   FROM inventory i
   JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
   JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year = 2001
     AND d.d_quarter_seq = 16
     AND d.d_month_seq BETWEEN 1 AND 3
     AND w.w_state = 'CA'
     AND w.w_warehouse_sq_ft > 500000
     AND i.inv_quantity_on_hand >= 500
     AND d.d_holiday = 'N'
),
agg_inventory AS (
   SELECT
       w_warehouse_name,
       w_warehouse_sq_ft,
       d_year,
       d_quarter_seq,
       SUM(inv_quantity_on_hand) AS total_quantity,
       AVG(inv_quantity_on_hand) AS avg_quantity_per_day
   FROM daily_inventory
   GROUP BY w_warehouse_name, w_warehouse_sq_ft, d_year, d_quarter_seq
   HAVING SUM(inv_quantity_on_hand) > 1000
)
SELECT
    a.w_warehouse_name,
    a.w_warehouse_sq_ft,
    a.d_year,
    a.d_quarter_seq,
    a.total_quantity,
    a.avg_quantity_per_day,
    RANK() OVER (PARTITION BY a.d_quarter_seq ORDER BY a.total_quantity DESC) AS warehouse_rank,
    CASE
        WHEN a.total_quantity > (SELECT AVG(total_quantity) FROM agg_inventory) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS performance_category
FROM agg_inventory a
ORDER BY a.d_quarter_seq, warehouse_rank
LIMIT 100
