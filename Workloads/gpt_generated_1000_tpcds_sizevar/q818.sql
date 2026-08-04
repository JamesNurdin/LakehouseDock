WITH sales_filtered AS (
  SELECT *
  FROM catalog_sales
  WHERE cs_catalog_page_sk IN (
    SELECT cp_catalog_page_sk
    FROM catalog_page
    WHERE cp_department = 'Shoes' AND cp_catalog_page_number BETWEEN 10 AND 15
  )
    AND cs_wholesale_cost > 30
    AND cs_net_paid_inc_ship_tax < 10000
),

full_ship_sales AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_catalog_page_sk,
    cs.cs_ship_mode_sk,
    cs.cs_ext_sales_price,
    cs.cs_net_paid,
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    sm.sm_contract
  FROM sales_filtered cs
  FULL OUTER JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
),

agg_by_dept_ship AS (
  SELECT
    cp.cp_department,
    sm.sm_ship_mode_id,
    SUM(fss.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt
  FROM full_ship_sales fss
  JOIN catalog_page cp
    ON fss.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm
    ON fss.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_contract LIKE 'I3u%'
  GROUP BY cp.cp_department, sm.sm_ship_mode_id
),

agg_by_dept AS (
  SELECT
    cp.cp_department,
    'ALL' AS sm_ship_mode_id,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt
  FROM sales_filtered cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  GROUP BY cp.cp_department
),

union_agg AS (
  SELECT cp_department, sm_ship_mode_id, total_sales, sales_cnt
  FROM agg_by_dept_ship
  UNION DISTINCT
  SELECT cp_department, sm_ship_mode_id, total_sales, sales_cnt
  FROM agg_by_dept
),

ship_info AS (
  SELECT
    sm_ship_mode_sk,
    sm_ship_mode_id,
    sm_carrier,
    sm_contract,
    ARRAY[sm_ship_mode_id, sm_carrier, sm_contract] AS info_arr
  FROM ship_mode
),

ship_unnested AS (
  SELECT
    sm_ship_mode_id,
    info_value,
    ROW_NUMBER() OVER (PARTITION BY sm_ship_mode_id ORDER BY info_value) AS info_seq
  FROM ship_info
  CROSS JOIN UNNEST(info_arr) AS t(info_value)
),

final AS (
  SELECT
    u.cp_department,
    u.sm_ship_mode_id,
    u.total_sales,
    u.sales_cnt,
    RANK() OVER (PARTITION BY u.cp_department ORDER BY u.total_sales DESC) AS dept_sales_rank,
    CASE
      WHEN u.sales_cnt > 100 THEN 'HIGH_VOLUME'
      WHEN u.sales_cnt BETWEEN 50 AND 100 THEN 'MEDIUM_VOLUME'
      ELSE 'LOW_VOLUME'
    END AS volume_category,
    su.info_value,
    su.info_seq
  FROM union_agg u
  LEFT JOIN ship_unnested su
    ON u.sm_ship_mode_id = su.sm_ship_mode_id
  WHERE u.total_sales > 5000
)

SELECT
  cp_department,
  sm_ship_mode_id,
  total_sales,
  sales_cnt,
  dept_sales_rank,
  volume_category,
  info_value,
  info_seq
FROM final
ORDER BY dept_sales_rank, total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
