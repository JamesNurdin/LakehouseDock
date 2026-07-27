WITH
  sales_agg AS (
    SELECT
      d.d_year,
      cp.cp_department,
      w.w_state,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt,
      CASE
        WHEN SUM(cs.cs_net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(cs.cs_net_profit) > 0      THEN 'MEDIUM'
        ELSE                                   'LOW'
      END AS profit_category
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN warehouse w        ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN time_dim t              ON cs.cs_sold_time_sk   = t.t_time_sk
    WHERE d.d_year BETWEEN 1998 AND 2000                       -- predicate 1
      AND cp.cp_department IN ('Sports', 'Books')             -- predicate 2
      AND w.w_state IS NOT NULL                               -- predicate 3
      AND t.t_hour BETWEEN 8 AND 20                           -- predicate 4
      AND cp.cp_type = 'A'                                    -- predicate 5
      AND w.w_city LIKE 'New%'                                -- predicate 6
    GROUP BY d.d_year, cp.cp_department, w.w_state
  ),

  returns_agg AS (
    SELECT
      d.d_year,
      cp.cp_department,
      w.w_state,
      SUM(cr.cr_return_amount) AS total_returns,
      COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp          ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN warehouse w        ON cr.cr_warehouse_sk   = w.w_warehouse_sk
    JOIN time_dim t              ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE d.d_year BETWEEN 1998 AND 2000                       -- predicate 1
      AND cp.cp_department IN ('Sports', 'Books')             -- predicate 2
      AND w.w_state IS NOT NULL                               -- predicate 3
      AND t.t_hour BETWEEN 8 AND 20                           -- predicate 4
      AND cp.cp_type = 'A'                                    -- predicate 5
      AND w.w_city LIKE 'New%'                                -- predicate 6
    GROUP BY d.d_year, cp.cp_department, w.w_state
  ),

  combined AS (
    SELECT
      d_year,
      cp_department,
      w_state,
      total_sales,
      total_profit,
      sales_cnt,
      profit_category,
      CAST(NULL AS double)   AS total_returns,
      CAST(NULL AS integer)  AS returns_cnt
    FROM sales_agg
    UNION ALL
    SELECT
      d_year,
      cp_department,
      w_state,
      CAST(NULL AS double)   AS total_sales,
      CAST(NULL AS double)   AS total_profit,
      CAST(NULL AS integer)  AS sales_cnt,
      CAST(NULL AS varchar)  AS profit_category,
      total_returns,
      returns_cnt
    FROM returns_agg
  ),

  yearly_summary AS (
    SELECT
      d_year,
      SUM(COALESCE(total_sales, 0))   AS year_sales,
      SUM(COALESCE(total_profit, 0))  AS year_profit,
      SUM(COALESCE(total_returns, 0)) AS year_returns,
      COUNT(DISTINCT cp_department)   AS dept_count
    FROM combined
    GROUP BY d_year
  )
SELECT
  d_year,
  year_sales,
  year_profit,
  year_returns,
  dept_count,
  CASE
    WHEN year_sales = 0 THEN 0
    ELSE CAST(year_returns AS double) / year_sales
  END AS return_rate
FROM yearly_summary
WHERE year_sales > 10000
ORDER BY d_year DESC, year_sales DESC
LIMIT 100
