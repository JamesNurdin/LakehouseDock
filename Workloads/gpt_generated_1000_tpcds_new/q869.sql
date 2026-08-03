WITH
store_ret_agg AS (
  SELECT
    sr.sr_item_sk,
    sr.sr_store_sk,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(sr.sr_return_quantity) AS total_store_return_qty,
    sr.sr_reason_sk
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE d.d_year = 2001
    AND r.r_reason_desc LIKE '%damaged%'
    AND sr.sr_return_quantity > 0
    AND sr.sr_return_amt > 0
  GROUP BY sr.sr_item_sk, sr.sr_store_sk, sr.sr_reason_sk
),
web_ret_agg AS (
  SELECT
    wr.wr_item_sk,
    wr.wr_web_page_sk,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    wr.wr_reason_sk
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE d.d_year = 2001
    AND r.r_reason_desc LIKE '%defective%'
    AND wr.wr_return_quantity > 0
    AND wr.wr_return_amt > 0
  GROUP BY wr.wr_item_sk, wr.wr_web_page_sk, wr.wr_reason_sk
),
item_inv AS (
  SELECT
    inv.inv_item_sk,
    inv.inv_warehouse_sk,
    inv.inv_quantity_on_hand,
    inv.inv_date_sk,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    i.i_current_price
  FROM inventory inv
  JOIN item i ON inv.inv_item_sk = i.i_item_sk
  JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND i.i_current_price BETWEEN 20 AND 500
),
common_items AS (
  SELECT sr_item_sk AS item_sk FROM store_ret_agg
  INTERSECT
  SELECT wr_item_sk AS item_sk FROM web_ret_agg
),
union_items AS (
  SELECT sr_item_sk AS item_sk FROM store_ret_agg
  UNION
  SELECT wr_item_sk AS item_sk FROM web_ret_agg
),
exclusive_items AS (
  SELECT item_sk FROM union_items
  EXCEPT
  SELECT item_sk FROM common_items
),
top_reasons AS (
  SELECT r_reason_sk, r_reason_desc
  FROM reason
  ORDER BY r_reason_sk
  LIMIT 3
),
date_range AS (
  SELECT d_date_sk
  FROM date_dim
  WHERE d_year = 2001
    AND d_month_seq BETWEEN 1 AND 12
),
cross_dates_reasons AS (
  SELECT dr.d_date_sk, tr.r_reason_sk
  FROM date_range dr
  CROSS JOIN top_reasons tr
),
final_data AS (
  SELECT
    ii.inv_item_sk,
    ii.i_product_name,
    ii.i_category,
    sr.s_store_name,
    wh.w_warehouse_name,
    wp.wp_url,
    sr_agg.total_store_return_amt,
    wr_agg.total_web_return_amt,
    cd.r_reason_desc,
    d.d_date
  FROM store_ret_agg sr_agg
  JOIN store sr ON sr_agg.sr_store_sk = sr.s_store_sk
  JOIN item_inv ii ON sr_agg.sr_item_sk = ii.inv_item_sk
  JOIN warehouse wh ON ii.inv_warehouse_sk = wh.w_warehouse_sk
  JOIN web_ret_agg wr_agg ON sr_agg.sr_item_sk = wr_agg.wr_item_sk
  JOIN web_page wp ON wr_agg.wr_web_page_sk = wp.wp_web_page_sk
  JOIN cross_dates_reasons cdr ON 1 = 1
  JOIN reason cd ON cdr.r_reason_sk = cd.r_reason_sk
  JOIN date_dim d ON cdr.d_date_sk = d.d_date_sk
  WHERE ii.i_current_price < 100
    AND sr.s_state = 'CA'
    AND wh.w_state = 'CA'
    AND wp.wp_type = 'content'
    AND wp.wp_creation_date_sk = d.d_date_sk
    AND EXISTS (SELECT 1 FROM exclusive_items e WHERE e.item_sk = sr_agg.sr_item_sk)
)
SELECT
  inv_item_sk,
  i_product_name,
  i_category,
  s_store_name,
  w_warehouse_name,
  wp_url,
  total_store_return_amt,
  total_web_return_amt,
  r_reason_desc,
  d_date
FROM final_data
ORDER BY total_store_return_amt DESC, total_web_return_amt DESC
LIMIT 100
