WITH
  sales_agg AS (
    SELECT
      i.i_item_id AS item_id,
      d.d_year AS year,
      SUM(cs.cs_net_paid_inc_ship) AS total_sales,
      SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY GROUPING SETS (
      (i.i_item_id, d.d_year),
      (i.i_item_id),
      (d.d_year)
    )
  ),
  returns_agg AS (
    SELECT
      i.i_item_id AS item_id,
      d.d_year AS year,
      SUM(sr.sr_return_amt) AS total_return,
      SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY GROUPING SETS (
      (i.i_item_id, d.d_year),
      (i.i_item_id),
      (d.d_year)
    )
  ),
  years AS (
    SELECT DISTINCT d.d_year
    FROM date_dim d
    WHERE d.d_year BETWEEN 1999 AND 2001
  ),
  dim AS (
    SELECT 'A' AS grp UNION ALL SELECT 'B'
  ),
  full_data AS (
    SELECT
      COALESCE(s.item_id, r.item_id) AS item_id,
      COALESCE(s.year, r.year) AS year,
      s.total_sales,
      r.total_return
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
      ON s.item_id = r.item_id AND s.year = r.year
  )
SELECT
  fd.item_id,
  fd.year,
  fd.total_sales,
  fd.total_return,
  d.grp
FROM full_data fd
CROSS JOIN dim d
WHERE EXISTS (
  SELECT 1
  FROM promotion p
  JOIN item i ON p.p_item_sk = i.i_item_sk
  WHERE i.i_item_id = fd.item_id
    AND p.p_discount_active = 'Y'
)
UNION ALL
SELECT
  i.i_item_id,
  y.d_year AS year,
  NULL AS total_sales,
  NULL AS total_return,
  'C' AS grp
FROM item i
CROSS JOIN years y
WHERE i.i_item_id NOT IN (SELECT item_id FROM full_data)
