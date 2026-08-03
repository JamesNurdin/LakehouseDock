WITH
sales_by_page AS (
  SELECT
    cp.cp_catalog_page_sk,
    cp.cp_type,
    sm.sm_ship_mode_id,
    d.d_date,
    SUM(cs.cs_net_paid) AS total_net_paid,
    LAG(SUM(cs.cs_net_paid)) OVER (PARTITION BY cp.cp_type ORDER BY d.d_date) AS prev_total_net_paid
  FROM catalog_sales cs
  RIGHT OUTER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2020
  GROUP BY
    cp.cp_catalog_page_sk,
    cp.cp_type,
    sm.sm_ship_mode_id,
    d.d_date
),
intersect_keys AS (
  SELECT cp.cp_catalog_page_sk
  FROM catalog_page cp
  INTERSECT
  SELECT cs.cs_catalog_page_sk
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2020
),
anti_join_sales AS (
  SELECT *
  FROM sales_by_page sbp
  WHERE sbp.cp_catalog_page_sk NOT IN (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_order_number < 0
  )
)
SELECT
  combined.cp_catalog_page_sk,
  combined.cp_type,
  combined.sm_ship_mode_id,
  combined.d_date,
  combined.total_net_paid,
  combined.prev_total_net_paid
FROM (
  SELECT
    sbp.cp_catalog_page_sk,
    sbp.cp_type,
    sbp.sm_ship_mode_id,
    sbp.d_date,
    sbp.total_net_paid,
    sbp.prev_total_net_paid
  FROM anti_join_sales sbp
  WHERE sbp.sm_ship_mode_id = 'AIR'
    AND sbp.cp_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM intersect_keys)

  UNION ALL

  SELECT
    sbp.cp_catalog_page_sk,
    sbp.cp_type,
    sbp.sm_ship_mode_id,
    sbp.d_date,
    sbp.total_net_paid,
    sbp.prev_total_net_paid
  FROM anti_join_sales sbp
  WHERE sbp.sm_ship_mode_id = 'RAIL'
    AND sbp.cp_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM intersect_keys)
) AS combined
ORDER BY combined.total_net_paid DESC, combined.d_date
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
