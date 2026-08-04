WITH
  filtered_items AS (
    SELECT
      i_item_sk,
      i_item_desc,
      regexp_extract(i_item_desc, '(\\w+)', 1) AS first_word,
      i_category
    FROM item
    WHERE regexp_like(i_item_desc, '(?i)color')
  ),
  reason_subset AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_desc LIKE '%color%'
       OR r_reason_desc LIKE '%make%'
  ),
  num_set AS (
    SELECT n
    FROM (VALUES (1), (2), (3)) AS t(n)
  ),
  dept_cross AS (
    SELECT cp.cp_department AS department, ns.n AS bucket
    FROM (SELECT DISTINCT cp_department FROM catalog_page) cp
    CROSS JOIN num_set ns
  )
SELECT
  dc.department,
  dc.bucket,
  COALESCE(rs.r_reason_desc, 'No Return') AS reason_desc,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
  COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
  ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rn
FROM dept_cross dc
JOIN catalog_page cp
  ON cp.cp_department = dc.department
JOIN catalog_sales cs
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN filtered_items fi
  ON fi.i_item_sk = cs.cs_item_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = cs.cs_order_number
  AND wr.wr_item_sk = fi.i_item_sk
LEFT JOIN reason_subset rs
  ON rs.r_reason_sk = wr.wr_reason_sk
GROUP BY
  dc.department,
  dc.bucket,
  rs.r_reason_desc
ORDER BY rn
LIMIT 100
