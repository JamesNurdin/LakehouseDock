WITH
  base AS (
    SELECT
      cr.cr_order_number,
      d.d_year,
      t.t_shift,
      hd_rfd.hd_dep_count        AS refunded_dep,
      hd_ret.hd_dep_count        AS returning_dep,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_return_tax,
      cr.cr_net_loss,
      CASE WHEN cr.cr_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_category,
      ARRAY[cr.cr_return_quantity, CAST(cr.cr_return_amount AS double)] AS qty_amount_arr
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd_rfd
      ON cr.cr_refunded_hdemo_sk = hd_rfd.hd_demo_sk
    JOIN household_demographics hd_ret
      ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002                      -- predicate 1
      AND t.t_shift IN ('first', 'second')                    -- predicate 2
      AND hd_rfd.hd_dep_count >= 1                           -- predicate 3
      AND cr.cr_return_tax > 0                               -- predicate 4
  ),

  unnested AS (
    SELECT
      b.*, 
      v.value   AS unnest_value,
      v.ordinality AS position
    FROM base b
    CROSS JOIN UNNEST(b.qty_amount_arr) WITH ORDINALITY AS v(value, ordinality)
  ),

  agg_unnest AS (
    SELECT
      cr_order_number,
      SUM(unnest_value) AS sum_qty_amount
    FROM unnested
    GROUP BY cr_order_number
  ),

  base_enhanced AS (
    SELECT
      b.*, 
      a.sum_qty_amount
    FROM base b
    LEFT JOIN agg_unnest a
      ON b.cr_order_number = a.cr_order_number
  ),

  agg1 AS (
    SELECT
      d_year,
      t_shift,
      loss_category,
      SUM(cr_net_loss)                AS sum_net_loss,
      COUNT(DISTINCT cr_order_number) AS cnt_orders,
      AVG(cr_return_quantity)         AS avg_quantity,
      SUM(sum_qty_amount)             AS total_qty_amount_sum
    FROM base_enhanced
    GROUP BY d_year, t_shift, loss_category
    HAVING SUM(cr_net_loss) > 500               -- HAVING predicate 1
       AND SUM(sum_qty_amount) > 1000           -- HAVING predicate 2
  ),

  running AS (
    SELECT
      d_year,
      t_shift,
      loss_category,
      sum_net_loss,
      cnt_orders,
      avg_quantity,
      total_qty_amount_sum,
      SUM(sum_net_loss) OVER (
        PARTITION BY loss_category
        ORDER BY d_year, t_shift
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS running_sum_net_loss
    FROM agg1
  ),

  high_loss_orders AS (
    SELECT cr_order_number FROM base WHERE cr_net_loss > 150
  ),

  large_quantity_orders AS (
    SELECT cr_order_number FROM base WHERE cr_return_quantity > 5
  ),

  intersect_orders AS (
    SELECT cr_order_number FROM high_loss_orders
    INTERSECT
    SELECT cr_order_number FROM large_quantity_orders
  )

SELECT
  r.d_year,
  r.t_shift,
  r.loss_category,
  r.sum_net_loss,
  r.running_sum_net_loss,
  r.cnt_orders,
  r.avg_quantity,
  r.total_qty_amount_sum,
  (
    SELECT COUNT(*)
    FROM base_enhanced be
    WHERE be.cr_order_number IN (SELECT cr_order_number FROM intersect_orders)
      AND be.loss_category = r.loss_category
  ) AS intersect_order_cnt,
  CASE WHEN r.loss_category = 'High' AND r.sum_net_loss > 1000 THEN 'Critical' ELSE 'Normal' END AS risk_level
FROM running r
ORDER BY r.d_year DESC, r.t_shift, r.loss_category
LIMIT 100
