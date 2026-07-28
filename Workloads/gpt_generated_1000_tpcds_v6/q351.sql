WITH
  sales AS (
    SELECT
      i.i_category AS category,
      'sales' AS metric,
      SUM(cs.cs_ext_sales_price) AS amount,
      CASE
        WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit'
        ELSE 'Loss'
      END AS flag
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '.*[A-Z]{2}[0-9]{3}.*')
      AND cp.cp_type LIKE 'C%'
    GROUP BY i.i_category
  ),

  returns AS (
    SELECT
      i.i_category AS category,
      'return' AS metric,
      SUM(cr.cr_return_amount) AS amount,
      CASE
        WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High'
        ELSE 'Low'
      END AS flag
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%damaged%'
      AND regexp_extract(i.i_item_desc, '(SPECIAL)-\w+', 1) = 'SPECIAL'
    GROUP BY i.i_category
  ),

  filtered_categories AS (
    SELECT DISTINCT i.i_category AS category
    FROM item i
    WHERE regexp_like(i.i_category, '^\\w+$')
  )

SELECT DISTINCT
  u.category,
  u.metric,
  u.amount,
  u.flag
FROM (
  SELECT * FROM sales
  UNION ALL
  SELECT * FROM returns
) u
WHERE u.category IN (SELECT category FROM filtered_categories)
ORDER BY u.category, u.metric DESC, u.amount DESC
LIMIT 100
