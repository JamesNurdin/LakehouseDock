WITH sales_agg AS (
  SELECT cs_warehouse_sk,
         cs_catalog_page_sk,
         MIN(cs_sold_time_sk) AS sold_time_sk,
         SUM(cs_ext_sales_price) AS total_sales,
         SUM(cs_net_profit) AS total_profit,
         COUNT(*) AS sales_cnt
  FROM catalog_sales
  WHERE cs_ext_ship_cost > 1000
    AND cs_coupon_amt < 200
    AND cs_ext_ship_cost IS NOT NULL
    AND cs_ext_sales_price > 0
  GROUP BY cs_warehouse_sk, cs_catalog_page_sk
),
warehouse_filt AS (
  SELECT w_warehouse_sk,
         w_city,
         w_state,
         w_zip,
         w_gmt_offset
  FROM warehouse
  WHERE w_zip LIKE '6%'
    AND w_state = 'CA'
),
time_filt AS (
  SELECT t_time_sk,
         t_am_pm,
         t_meal_time
  FROM time_dim
  WHERE t_am_pm = 'PM'
    AND t_meal_time = 'dinner'
),
sub1 AS (
  SELECT cs_catalog_page_sk AS page_sk,
         cs_sold_date_sk AS sold_date_sk
  FROM catalog_sales
  WHERE cs_ext_ship_cost > 2000
),
sub2 AS (
  SELECT cs_catalog_page_sk AS page_sk,
         cs_sold_date_sk AS sold_date_sk
  FROM catalog_sales
  WHERE cs_ext_ship_cost BETWEEN 1000 AND 2000
),
union_sub AS (
  SELECT page_sk, sold_date_sk FROM sub1
  UNION
  SELECT page_sk, sold_date_sk FROM sub2
),
intersect_sub AS (
  SELECT page_sk, sold_date_sk FROM sub1
  INTERSECT
  SELECT page_sk, sold_date_sk FROM sub2
),
base AS (
  SELECT
    sa.cs_warehouse_sk,
    w.w_city,
    w.w_state,
    cp.cp_department,
    ti.t_meal_time,
    CASE WHEN sa.total_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    sa.total_sales,
    sa.total_profit,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY sa.total_sales DESC) AS sales_rank,
    SUM(sa.total_sales) OVER (PARTITION BY w.w_state) AS state_sales_total,
    lc.item_cnt
  FROM sales_agg sa
  JOIN warehouse_filt w ON sa.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN time_filt ti ON sa.sold_time_sk = ti.t_time_sk
  CROSS JOIN LATERAL (
    SELECT COUNT(*) AS item_cnt
    FROM catalog_sales cs2
    WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
      AND cs2.cs_catalog_page_sk = cp.cp_catalog_page_sk
      AND cs2.cs_sold_time_sk = ti.t_time_sk
  ) AS lc
  WHERE lc.item_cnt > 5
)
SELECT
  state,
  department,
  profit_flag,
  SUM(total_sales) AS sum_sales,
  SUM(total_profit) AS sum_profit,
  COUNT(*) AS row_cnt,
  GROUPING(state) AS grp_state,
  GROUPING(department) AS grp_department,
  GROUPING(profit_flag) AS grp_profit
FROM (
  SELECT
    w_state AS state,
    cp_department AS department,
    profit_flag,
    total_sales,
    total_profit,
    sales_rank,
    state_sales_total,
    item_cnt
  FROM base
) AS ranked_sales
GROUP BY GROUPING SETS (
  (state, department, profit_flag),
  (state, department),
  (state),
  ()
)
ORDER BY sum_sales DESC
LIMIT 100
