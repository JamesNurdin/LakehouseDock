WITH sales_agg AS (
  SELECT
    d.d_year,
    d.d_moy,
    cp.cp_department,
    'sale' AS trans_type,
    SUM(cs.cs_net_profit) AS amount
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE EXISTS (
    SELECT 1
    FROM promotion p
    JOIN date_dim pd ON p.p_start_date_sk = pd.d_date_sk
    WHERE p.p_item_sk = cs.cs_item_sk
      AND pd.d_date_sk = cs.cs_sold_date_sk
  )
  GROUP BY d.d_year, d.d_moy, cp.cp_department
),
returns_agg AS (
  SELECT
    d.d_year,
    d.d_moy,
    cp.cp_department,
    'return' AS trans_type,
    SUM(cr.cr_net_loss) AS amount
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  GROUP BY d.d_year, d.d_moy, cp.cp_department
)
SELECT d_year, d_moy, cp_department, trans_type, amount
FROM (
  SELECT d_year, d_moy, cp_department, trans_type, amount FROM sales_agg
  UNION ALL
  SELECT d_year, d_moy, cp_department, trans_type, amount FROM returns_agg
) combined
ORDER BY d_year DESC, d_moy DESC, cp_department, trans_type
LIMIT 100
