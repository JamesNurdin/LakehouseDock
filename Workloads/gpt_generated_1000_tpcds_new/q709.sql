WITH
  store_items AS (
    SELECT
      ss.ss_item_sk AS item_sk,
      i.i_item_desc AS i_item_desc,
      i.i_current_price AS i_current_price,
      d.d_year AS d_year,
      CONCAT('Item_', CAST(ss.ss_item_sk AS VARCHAR)) AS item_key,
      ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY d.d_date) AS rn
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
      AND i.i_item_desc LIKE '%BRAND%'
  ),
  return_items AS (
    SELECT
      cr.cr_item_sk AS item_sk,
      i.i_item_desc AS i_item_desc,
      i.i_current_price AS i_current_price,
      d.d_year AS d_year,
      CONCAT('Ret_', CAST(cr.cr_item_sk AS VARCHAR)) AS item_key,
      ROW_NUMBER() OVER (PARTITION BY cr.cr_item_sk ORDER BY d.d_date) AS rn
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%damaged%'
      AND regexp_like(r.r_reason_desc, 'Package.*')
  ),
  union_items AS (
    SELECT item_sk, i_item_desc, i_current_price, d_year, item_key, rn
    FROM store_items
    UNION
    SELECT item_sk, i_item_desc, i_current_price, d_year, item_key, rn
    FROM return_items
  ),
  store_info AS (
    SELECT s.s_store_sk,
           s.s_store_name,
           d.d_year AS closed_year
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
  ),
  call_center_info AS (
    SELECT cc.cc_call_center_sk,
           cc.cc_name,
           d.d_year AS closed_year
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
  ),
  full_join_info AS (
    SELECT
      COALESCE(si.s_store_sk, -1) AS entity_id,
      COALESCE(si.s_store_name, cc.cc_name) AS entity_name,
      COALESCE(si.closed_year, cc.closed_year) AS year
    FROM store_info si
    FULL OUTER JOIN call_center_info cc ON si.closed_year = cc.closed_year
  ),
  common_items AS (
    SELECT item_sk FROM store_items
    INTERSECT
    SELECT item_sk FROM return_items
  )
SELECT
  fj.entity_id,
  fj.entity_name,
  fj.year,
  ui.d_year,
  ui.i_item_desc,
  ui.i_current_price,
  COUNT(*) OVER (PARTITION BY ui.item_sk) AS item_occurrences,
  ROW_NUMBER() OVER (ORDER BY ui.i_current_price DESC) AS row_num
FROM union_items ui
JOIN common_items ci ON ui.item_sk = ci.item_sk
JOIN full_join_info fj ON ui.d_year = fj.year
WHERE ui.rn = 1
ORDER BY row_num
LIMIT 100
