WITH
  sold_items AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_net_profit,
      cs.cs_ext_sales_price,
      cs.cs_ext_discount_amt,
      i.i_item_desc,
      i.i_category,
      i.i_brand,
      cp.cp_department
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(i.i_item_desc, '[0-9]{3}')
      AND i.i_category LIKE 'Elect%'
  ),
  returned_items AS (
    SELECT
      wr.wr_item_sk,
      wr.wr_return_amt,
      r.r_reason_desc
    FROM web_returns wr
    JOIN item i
      ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, 'service')
      AND r.r_reason_desc LIKE '%location%'
  ),
  unsold_items AS (
    SELECT cs.cs_item_sk
    FROM catalog_sales cs
    EXCEPT
    SELECT wr.wr_item_sk
    FROM web_returns wr
  ),
  filtered_sold AS (
    SELECT
      si.cs_item_sk,
      si.i_item_desc,
      si.i_category,
      si.i_brand,
      si.cp_department,
      si.cs_net_profit,
      si.cs_ext_sales_price,
      si.cs_ext_discount_amt,
      CASE WHEN si.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_level,
      (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN catalog_page cp2 ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
        WHERE cp2.cp_department = si.cp_department
      ) AS dept_avg_profit,
      ri.wr_return_amt,
      ri.r_reason_desc
    FROM sold_items si
    LEFT JOIN returned_items ri
      ON si.cs_item_sk = ri.wr_item_sk
    JOIN unsold_items ui
      ON si.cs_item_sk = ui.cs_item_sk
  )
SELECT
  fs.cs_item_sk,
  fs.i_item_desc,
  fs.i_category,
  fs.i_brand,
  fs.cp_department,
  fs.cs_net_profit,
  fs.profit_level,
  fs.dept_avg_profit,
  fs.wr_return_amt,
  CASE
    WHEN fs.wr_return_amt IS NULL THEN 'No Return'
    WHEN fs.wr_return_amt > 100 THEN 'Large Return'
    ELSE 'Small Return'
  END AS return_category,
  CONCAT(fs.i_brand, ' - ', fs.cp_department) AS brand_dept,
  regexp_extract(fs.i_item_desc, '(\\d{3})', 1) AS three_digit_code,
  SUBSTRING(fs.r_reason_desc, 1, 20) AS short_reason,
  RANK() OVER (PARTITION BY fs.i_category ORDER BY fs.cs_net_profit DESC) AS category_rank,
  ROW_NUMBER() OVER (ORDER BY fs.cs_net_profit DESC) AS overall_row_num
FROM filtered_sold fs
WHERE fs.i_item_desc LIKE '%XYZ%'
ORDER BY fs.cs_net_profit DESC
LIMIT 100
