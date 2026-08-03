WITH filtered_base AS (
  SELECT
    cr.cr_order_number AS order_number,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_net_loss,
    d.d_year,
    d.d_day_name,
    t.t_hour,
    t.t_sub_shift,
    r.r_reason_desc,
    wr.wr_return_amt_inc_tax,
    wr.wr_return_tax,
    wr.wr_net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                      AND wr.wr_returned_time_sk = t.t_time_sk
                      AND wr.wr_reason_sk = r.r_reason_sk
  WHERE d.d_year = 2001
    AND d.d_day_name = 'Tuesday'
    AND t.t_sub_shift = 'morning'
),
per_order AS (
  SELECT
    order_number,
    SUM(cr_return_amount) AS sum_return_amount,
    SUM(wr_return_amt_inc_tax) AS sum_web_return_inc_tax,
    COUNT(*) AS txn_cnt
  FROM filtered_base
  GROUP BY order_number
),
avg_metrics AS (
  SELECT
    AVG(sum_return_amount) AS avg_return_amount,
    AVG(sum_web_return_inc_tax) AS avg_web_return_inc_tax
  FROM per_order
),
order_set_a AS (
  SELECT cr_order_number AS order_number
  FROM catalog_returns
  WHERE cr_return_amount > 150
),
order_set_b AS (
  SELECT wr_order_number AS order_number
  FROM web_returns
  WHERE wr_return_amt_inc_tax > 200
),
common_orders AS (
  SELECT order_number FROM order_set_a INTERSECT SELECT order_number FROM order_set_b
),
unique_to_a AS (
  SELECT order_number FROM order_set_a EXCEPT SELECT order_number FROM order_set_b
)
SELECT
  po.order_number,
  po.sum_return_amount,
  po.sum_web_return_inc_tax,
  po.txn_cnt,
  am.avg_return_amount,
  am.avg_web_return_inc_tax,
  co.order_number AS common_order,
  ua.order_number AS unique_order_a,
  lt.avg_tax AS avg_return_tax_per_order
FROM per_order po
JOIN avg_metrics am ON true
LEFT JOIN common_orders co ON po.order_number = co.order_number
LEFT JOIN unique_to_a ua ON po.order_number = ua.order_number
CROSS JOIN LATERAL (
  SELECT AVG(cr_return_tax) AS avg_tax
  FROM filtered_base fb
  WHERE fb.order_number = po.order_number
) lt
ORDER BY po.sum_return_amount DESC
OFFSET 20
LIMIT 100
