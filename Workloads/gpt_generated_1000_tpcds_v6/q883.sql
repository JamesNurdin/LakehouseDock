WITH sales_inventory AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_item_sk,
       cs.cs_quantity,
       cs.cs_net_paid_inc_ship_tax,
       d.d_year,
       d.d_month_seq,
       inv.inv_quantity_on_hand,
       CASE WHEN cs.cs_quantity * cs.cs_net_paid_inc_ship_tax > 5000 THEN 'HIGH' ELSE 'LOW' END AS qty_value_flag
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND cs.cs_quantity > 1
     AND inv.inv_quantity_on_hand > 100
),
agg1 AS (
   SELECT
       d_year,
       d_month_seq,
       qty_value_flag,
       SUM(cs_net_paid_inc_ship_tax) AS total_paid,
       SUM(cs_quantity) AS total_qty,
       COUNT(DISTINCT cs_item_sk) AS distinct_items
   FROM sales_inventory
   GROUP BY d_year, d_month_seq, qty_value_flag
),
final AS (
   SELECT
       d_year,
       d_month_seq,
       qty_value_flag,
       total_paid,
       total_qty,
       distinct_items,
       AVG(total_paid) OVER (PARTITION BY qty_value_flag ORDER BY d_month_seq) AS avg_paid_running,
       RANK() OVER (PARTITION BY qty_value_flag ORDER BY total_paid DESC) AS paid_rank
   FROM agg1
   WHERE total_qty > 10
)
SELECT
   d_year,
   d_month_seq,
   qty_value_flag,
   total_paid,
   total_qty,
   distinct_items,
   avg_paid_running,
   paid_rank
FROM final
ORDER BY d_year DESC, d_month_seq ASC, total_paid DESC
LIMIT 100
