WITH
  sampled_sales AS (
    SELECT
      cs_order_number,
      cs_net_paid_inc_tax,
      cs_wholesale_cost,
      cs_quantity,
      cs_ship_addr_sk,
      cs_sold_time_sk
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  filtered AS (
    SELECT
      cs_order_number,
      cs_net_paid_inc_tax,
      cs_wholesale_cost,
      cs_quantity,
      cs_ship_addr_sk,
      cs_sold_time_sk
    FROM sampled_sales
    WHERE cs_wholesale_cost BETWEEN 30 AND 60
      AND cs_quantity >= 2
      AND cs_net_paid_inc_tax > 500
      AND cs_ship_addr_sk IN (5947632, 2121279, 2701385, 3319971, 1128744)
      AND cs_sold_time_sk IS NOT NULL
  ),
  joined AS (
    SELECT
      f.cs_order_number,
      f.cs_net_paid_inc_tax,
      f.cs_wholesale_cost,
      f.cs_quantity,
      f.cs_ship_addr_sk,
      t.t_shift,
      t.t_minute
    FROM filtered f
    JOIN time_dim t
      ON f.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_shift IN ('first', 'second')
      AND t.t_minute BETWEEN 5 AND 20
  ),
  ranked AS (
    SELECT
      j.cs_order_number,
      j.cs_net_paid_inc_tax,
      j.cs_wholesale_cost,
      j.cs_quantity,
      j.cs_ship_addr_sk,
      j.t_shift,
      j.t_minute,
      ROW_NUMBER() OVER (PARTITION BY j.t_shift ORDER BY j.cs_net_paid_inc_tax DESC) AS rn_shift,
      RANK() OVER (ORDER BY j.cs_wholesale_cost ASC) AS rank_wholesale
    FROM joined j
  ),
  sub1 AS (
    SELECT cs_order_number FROM ranked WHERE rn_shift <= 10
  ),
  sub2 AS (
    SELECT cs_order_number FROM ranked WHERE rank_wholesale <= 20
  ),
  inter AS (
    SELECT cs_order_number FROM sub1
    INTERSECT
    SELECT cs_order_number FROM sub2
  ),
  sub3 AS (
    SELECT cs_order_number FROM ranked WHERE cs_quantity > 5
  ),
  sub4 AS (
    SELECT cs_order_number FROM ranked WHERE cs_net_paid_inc_tax < 2000
  ),
  final_keys AS (
    SELECT cs_order_number FROM inter
    EXCEPT
    SELECT cs_order_number FROM sub3
  )
SELECT
  r.cs_order_number,
  r.cs_net_paid_inc_tax,
  r.cs_wholesale_cost,
  r.cs_quantity,
  r.cs_ship_addr_sk,
  r.t_shift,
  r.t_minute,
  r.rn_shift,
  r.rank_wholesale
FROM ranked r
JOIN final_keys fk ON r.cs_order_number = fk.cs_order_number
ORDER BY r.cs_net_paid_inc_tax DESC, r.cs_order_number
OFFSET 0
LIMIT 100
