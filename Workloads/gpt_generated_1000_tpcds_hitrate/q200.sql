WITH daily_stats AS (
  SELECT
    i.inv_item_sk,
    i.inv_warehouse_sk,
    d.d_date,
    SUM(i.inv_quantity_on_hand) AS total_qty,
    COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
    MAX(p.p_cost) AS max_cost,
    MIN(p.p_cost) AS min_cost
  FROM inventory i
  JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
  JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
  WHERE d.d_day_name IN ('Monday', 'Tuesday', 'Wednesday')
    AND d.d_following_holiday = 'N'
    AND d.d_current_quarter = 'Y'
    AND d.d_year = 2001
    AND p.p_channel_press = 'N'
    AND p.p_channel_radio = 'N'
    AND i.inv_quantity_on_hand > 0
    AND p.p_cost > 0
  GROUP BY i.inv_item_sk, i.inv_warehouse_sk, d.d_date
),

running_stats AS (
  SELECT
    inv_item_sk,
    inv_warehouse_sk,
    d_date,
    total_qty,
    promo_cnt,
    max_cost,
    min_cost,
    SUM(total_qty) OVER (PARTITION BY inv_item_sk ORDER BY d_date
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_qty,
    LAG(total_qty) OVER (PARTITION BY inv_item_sk ORDER BY d_date) AS prev_qty
  FROM daily_stats
)

SELECT
  inv_item_sk,
  inv_warehouse_sk,
  MIN(d_date) AS first_date,
  MAX(d_date) AS last_date,
  SUM(running_qty) AS sum_running_qty,
  COUNT(DISTINCT promo_cnt) AS distinct_promo_cnt,
  COUNT(DISTINCT max_cost) AS distinct_max_cost,
  AVG(total_qty) AS avg_daily_qty,
  MAX(prev_qty) AS max_prev_qty
FROM running_stats
WHERE running_qty > 0
  AND prev_qty IS NOT NULL
  AND total_qty >= 10
  AND promo_cnt >= 1
  AND max_cost > 0
  AND min_cost >= 0
GROUP BY inv_item_sk, inv_warehouse_sk
HAVING SUM(total_qty) > 100
ORDER BY sum_running_qty DESC
LIMIT 100
