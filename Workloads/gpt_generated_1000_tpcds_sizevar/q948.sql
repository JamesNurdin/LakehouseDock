WITH sales_with_array AS (
  SELECT
    ss.ss_sold_time_sk,
    ss.ss_wholesale_cost,
    ss.ss_list_price,
    ARRAY[ss.ss_wholesale_cost, ss.ss_list_price] AS cost_array,
    ss.ss_ext_tax,
    ss.ss_net_profit
  FROM store_sales ss
  WHERE ss.ss_wholesale_cost > 20
),

expanded AS (
  SELECT
    s.ss_sold_time_sk,
    s.ss_wholesale_cost,
    s.ss_list_price,
    s.ss_ext_tax,
    s.ss_net_profit,
    u.val AS cost_value,
    u.ordinality AS cost_position
  FROM sales_with_array s
  CROSS JOIN UNNEST(s.cost_array) WITH ORDINALITY AS u(val, ordinality)
),

full_joined AS (
  SELECT
    e.ss_sold_time_sk,
    e.cost_value,
    e.cost_position,
    t.t_time_sk,
    t.t_sub_shift,
    t.t_minute
  FROM expanded e
  FULL OUTER JOIN time_dim t
    ON e.ss_sold_time_sk = t.t_time_sk
),

set1 AS (
  SELECT
    fj.ss_sold_time_sk,
    fj.cost_value,
    fj.t_sub_shift,
    ROW_NUMBER() OVER (PARTITION BY fj.ss_sold_time_sk ORDER BY fj.cost_position) AS rn
  FROM full_joined fj
  WHERE fj.t_sub_shift IN ('morning', 'afternoon')
),

set2 AS (
  SELECT
    fj.ss_sold_time_sk,
    fj.cost_value,
    fj.t_sub_shift,
    ROW_NUMBER() OVER (PARTITION BY fj.ss_sold_time_sk ORDER BY fj.cost_position DESC) AS rn
  FROM full_joined fj
  WHERE fj.t_sub_shift IN ('evening', 'night')
),

combined AS (
  SELECT ss_sold_time_sk, cost_value, t_sub_shift, rn FROM set1
  UNION ALL
  SELECT ss_sold_time_sk, cost_value, t_sub_shift, rn FROM set2
),

key_exclusion AS (
  SELECT ss_sold_time_sk FROM store_sales
  EXCEPT
  SELECT t_time_sk FROM time_dim WHERE t_sub_shift = 'night'
)

SELECT
  c.ss_sold_time_sk,
  c.cost_value,
  c.t_sub_shift,
  c.rn,
  CASE WHEN ke.ss_sold_time_sk IS NOT NULL THEN 'MissingInTimeDim' ELSE 'Present' END AS presence_flag
FROM combined c
LEFT JOIN key_exclusion ke
  ON c.ss_sold_time_sk = ke.ss_sold_time_sk
WHERE EXISTS (
  SELECT 1 FROM store_sales ss2
  WHERE ss2.ss_sold_time_sk = c.ss_sold_time_sk
    AND ss2.ss_net_profit > 500
)
ORDER BY c.rn DESC, c.ss_sold_time_sk
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
