WITH joined AS (
  SELECT
    d.d_year,
    d.d_week_seq,
    t.t_shift,
    cs.cs_order_number,
    cs.cs_net_paid,
    ss.ss_ticket_number,
    ss.ss_net_paid,
    inv.inv_quantity_on_hand,
    inv.inv_warehouse_sk
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
   AND ss.ss_sold_time_sk = t.t_time_sk
  JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
)
SELECT
  d_year,
  d_week_seq,
  t_shift,
  total_catalog_net_paid,
  total_store_net_paid,
  total_inventory_on_hand,
  distinct_catalog_orders,
  distinct_store_tickets
FROM (
   SELECT
     d_year,
     d_week_seq,
     t_shift,
     SUM(cs_net_paid) AS total_catalog_net_paid,
     SUM(ss_net_paid) AS total_store_net_paid,
     SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
     COUNT(DISTINCT cs_order_number) AS distinct_catalog_orders,
     COUNT(DISTINCT ss_ticket_number) AS distinct_store_tickets,
     ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(cs_net_paid) + SUM(ss_net_paid) DESC) AS rn
   FROM joined
   WHERE d_year = 2002
     AND d_week_seq BETWEEN 10 AND 20
     AND t_shift = 'first'
     AND inv_warehouse_sk IN (6, 7, 8)
   GROUP BY d_year, d_week_seq, t_shift
) ranked
WHERE rn <= 5
ORDER BY d_year, rn
LIMIT 100
