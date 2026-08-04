WITH sampled_sales AS (
  SELECT *
  FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),
sales_with_dims AS (
  SELECT
    ss.cs_order_number,
    ss.cs_net_profit,
    ss.cs_quantity,
    cc.cc_market_manager AS manager,
    cp.cp_department AS department,
    ds_sold.d_year AS sold_year,
    ds_ship.d_year AS ship_year,
    bc.c_first_name AS bill_first_name,
    sc.c_first_name AS ship_first_name
  FROM sampled_sales ss
  LEFT JOIN date_dim ds_sold
    ON ss.cs_sold_date_sk = ds_sold.d_date_sk
  LEFT JOIN date_dim ds_ship
    ON ss.cs_ship_date_sk = ds_ship.d_date_sk
  LEFT JOIN customer bc
    ON ss.cs_bill_customer_sk = bc.c_customer_sk
  LEFT JOIN customer sc
    ON ss.cs_ship_customer_sk = sc.c_customer_sk
  LEFT JOIN call_center cc
    ON ss.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN catalog_page cp
    ON ss.cs_catalog_page_sk = cp.cp_catalog_page_sk
),
returns_with_dims AS (
  SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_returned_date_sk,
    dr.d_year AS return_year,
    rc.cc_market_manager AS manager,
    rp.cp_department AS department,
    r.r_reason_desc AS reason_desc
  FROM catalog_returns cr
  LEFT JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
  LEFT JOIN call_center rc
    ON cr.cr_call_center_sk = rc.cc_call_center_sk
  LEFT JOIN catalog_page rp
    ON cr.cr_catalog_page_sk = rp.cp_catalog_page_sk
  LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
),
sales_with_returns AS (
  SELECT s.*, r.cr_return_amount, r.cr_return_quantity, r.return_year, r.reason_desc
  FROM sales_with_dims s
  LEFT JOIN returns_with_dims r
    ON s.cs_order_number = r.cr_order_number
),
sales_with_existing_returns AS (
  SELECT *
  FROM sales_with_returns s
  WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = s.cs_order_number
  )
),
agg_sales AS (
  SELECT
    manager,
    department,
    sold_year AS year,
    SUM(cs_net_profit) AS total_profit,
    SUM(cs_quantity) AS total_quantity
  FROM sales_with_existing_returns
  GROUP BY ROLLUP (manager, department, sold_year)
),
agg_returns AS (
  SELECT
    manager,
    department,
    return_year AS year,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_return_quantity) AS total_return_quantity
  FROM sales_with_existing_returns
  WHERE cr_return_amount IS NOT NULL
  GROUP BY ROLLUP (manager, department, return_year)
),
full_agg AS (
  SELECT
    COALESCE(a.manager, r.manager) AS manager,
    COALESCE(a.department, r.department) AS department,
    COALESCE(a.year, r.year) AS year,
    a.total_profit,
    a.total_quantity,
    r.total_return_amount,
    r.total_return_quantity
  FROM agg_sales a
  FULL OUTER JOIN agg_returns r
    ON a.manager = r.manager
   AND a.department = r.department
   AND a.year = r.year
)
SELECT *
FROM full_agg
EXCEPT
SELECT manager, department, year, total_profit, total_quantity, total_return_amount, total_return_quantity
FROM full_agg
WHERE total_return_amount IS NULL
ORDER BY manager, department, year
