WITH
  cs_agg AS (
    SELECT
      cs_warehouse_sk,
      cs_sold_time_sk,
      SUM(cs_ext_sales_price)          AS total_cs_sales,
      SUM(cs_net_profit)               AS total_cs_profit,
      COUNT(*)                         AS cs_orders
    FROM catalog_sales
    WHERE cs_wholesale_cost > 50
      AND cs_quantity >= 1
      AND cs_ext_discount_amt < 500   -- predicate 1
      AND cs_ship_date_sk BETWEEN 2450800 AND 2450900  -- predicate 2
    GROUP BY cs_warehouse_sk, cs_sold_time_sk
    HAVING SUM(cs_ext_sales_price) > 1000   -- predicate 3 (in HAVING)
  ),
  ws_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)   -- 10 % sample
    WHERE ws_ext_list_price > 1000            -- predicate 4
      AND ws_quantity BETWEEN 1 AND 10
  ),
  intersect_warehouses AS (
    SELECT cs_warehouse_sk AS w_warehouse_sk FROM cs_agg
    INTERSECT
    SELECT ws_warehouse_sk FROM ws_sample
  ),
  time_filt AS (
    SELECT *
    FROM time_dim
    WHERE t_hour BETWEEN 8 AND 17
      AND t_minute IN (12, 15, 10)
      AND t_am_pm = 'PM'
  )
SELECT
  warehouse_name,
  state,
  hour,
  minute,
  combined_sales,
  combined_profit,
  ROW_NUMBER() OVER (ORDER BY combined_sales DESC)          AS global_row_num,
  RANK()       OVER (PARTITION BY state ORDER BY combined_sales DESC) AS state_rank
FROM (
  SELECT
    w.w_warehouse_name  AS warehouse_name,
    w.w_state           AS state,
    t.t_hour            AS hour,
    t.t_minute          AS minute,
    (cs.total_cs_sales + ws.ws_ext_sales_price) AS combined_sales,
    (cs.total_cs_profit + ws.ws_net_profit)      AS combined_profit
  FROM cs_agg cs
  JOIN ws_sample ws
    ON cs.cs_warehouse_sk = ws.ws_warehouse_sk
   AND cs.cs_sold_time_sk = ws.ws_sold_time_sk
  JOIN warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
  JOIN time_filt t
    ON t.t_time_sk = cs.cs_sold_time_sk
  JOIN intersect_warehouses ik
    ON ik.w_warehouse_sk = w.w_warehouse_sk
  WHERE w.w_state = 'CA'            -- predicate 5
    AND w.w_gmt_offset BETWEEN -8 AND -5   -- predicate 6

  UNION

  SELECT
    w.w_warehouse_name,
    w.w_state,
    t.t_hour,
    t.t_minute,
    (cs.total_cs_sales + ws.ws_ext_sales_price),
    (cs.total_cs_profit + ws.ws_net_profit)
  FROM cs_agg cs
  JOIN ws_sample ws
    ON cs.cs_warehouse_sk = ws.ws_warehouse_sk
   AND cs.cs_sold_time_sk = ws.ws_sold_time_sk
  JOIN warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
  JOIN time_filt t
    ON t.t_time_sk = cs.cs_sold_time_sk
  JOIN intersect_warehouses ik
    ON ik.w_warehouse_sk = w.w_warehouse_sk
  WHERE w.w_state = 'NY'            -- predicate 7
    AND w.w_gmt_offset BETWEEN -5 AND -3   -- predicate 8
) AS unioned
ORDER BY combined_sales DESC
LIMIT 100
