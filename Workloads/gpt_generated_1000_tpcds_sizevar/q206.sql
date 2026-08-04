WITH
  inv_agg AS (
    SELECT
      inv_item_sk,
      inv_date_sk,
      SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
  ),
  store_keys AS (
    SELECT sr_store_sk FROM store_returns
    INTERSECT
    SELECT s_store_sk FROM store
  )
SELECT
  s.s_store_name,
  d_ret.d_date AS return_date,
  i.i_category,
  i.i_product_name,
  inv_agg.total_qty,
  SUM(sr.sr_return_amt) AS total_return_amount,
  ws.web_name,
  ROW_NUMBER() OVER (ORDER BY SUM(sr.sr_return_amt) DESC) AS rn
FROM store_returns sr
JOIN date_dim d_ret
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN item i
  ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN inv_agg
  ON i.i_item_sk = inv_agg.inv_item_sk
  AND d_ret.d_date_sk = inv_agg.inv_date_sk
JOIN catalog_page cp
  ON cp.cp_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_cp_end
  ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_ws_close
  ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN store_keys sk
  ON s.s_store_sk = sk.sr_store_sk
GROUP BY
  s.s_store_name,
  d_ret.d_date,
  i.i_category,
  i.i_product_name,
  inv_agg.total_qty,
  ws.web_name
ORDER BY total_return_amount DESC
LIMIT 100
