WITH
  sales_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      SUM(ss.ss_ext_sales_price) AS sales_amount,
      SUM(ss.ss_quantity) AS units_sold,
      CASE WHEN SUM(ss.ss_ext_sales_price) > 500000 THEN 'HIGH' ELSE 'LOW' END AS sales_band
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, i.i_category
  ),
  returns_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      SUM(wr.wr_return_amt) AS return_amount,
      SUM(wr.wr_return_quantity) AS units_returned,
      CASE WHEN SUM(wr.wr_return_amt) > 200000 THEN 'HIGH' ELSE 'LOW' END AS return_band
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, i.i_category
  ),
  combined AS (
    SELECT
      COALESCE(s.year, r.year) AS year,
      COALESCE(s.category, r.category) AS category,
      s.sales_amount,
      r.return_amount
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
      ON s.year = r.year AND s.category = r.category
  ),
  combined_grouped AS (
    SELECT
      year,
      category,
      SUM(sales_amount) AS sales_amount,
      SUM(return_amount) AS return_amount,
      CASE
        WHEN SUM(COALESCE(sales_amount, 0)) - SUM(COALESCE(return_amount, 0)) > 300000 THEN 'POSITIVE'
        WHEN SUM(COALESCE(sales_amount, 0)) - SUM(COALESCE(return_amount, 0)) < -300000 THEN 'NEGATIVE'
        ELSE 'NEUTRAL'
      END AS net_indicator
    FROM combined
    GROUP BY GROUPING SETS (
      (year, category),
      (year),
      ()
    )
  ),
  inventory_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      SUM(inv.inv_quantity_on_hand) AS inventory_qty,
      CASE WHEN SUM(inv.inv_quantity_on_hand) > 100000 THEN 'HIGH' ELSE 'LOW' END AS inventory_band
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, i.i_category
  ),
  inventory_grouped AS (
    SELECT
      year,
      category,
      CAST(SUM(inventory_qty) AS decimal(15,2)) AS sales_amount,
      CAST(NULL AS decimal(7,2)) AS return_amount,
      CASE
        WHEN SUM(inventory_qty) > 200000 THEN 'POSITIVE'
        WHEN SUM(inventory_qty) < 50000 THEN 'NEGATIVE'
        ELSE 'NEUTRAL'
      END AS net_indicator
    FROM inventory_agg
    GROUP BY GROUPING SETS (
      (year, category),
      (year),
      ()
    )
  )
SELECT
  year,
  category,
  sales_amount,
  return_amount,
  net_indicator
FROM combined_grouped
UNION ALL
SELECT
  year,
  category,
  sales_amount,
  return_amount,
  net_indicator
FROM inventory_grouped
ORDER BY year DESC NULLS LAST, category
LIMIT 100
