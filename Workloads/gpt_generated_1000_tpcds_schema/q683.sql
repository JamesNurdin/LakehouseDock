/* goal: Analyze total net loss by year and reason category across store, catalog, and web returns, compare ticket numbers without returns, and find high‑value orders appearing in both catalog and web returns */
WITH
  -- ticket numbers that have a sale but no corresponding store return
  tickets_without_return AS (
    SELECT COUNT(*) AS cnt
    FROM (
      SELECT ss_ticket_number FROM store_sales
      EXCEPT
      SELECT sr_ticket_number FROM store_returns
    ) t
  ),

  -- order numbers that appear in both catalog and web returns with high return amounts
  common_high_value_orders AS (
    SELECT COUNT(*) AS cnt
    FROM (
      SELECT cr_order_number FROM catalog_returns WHERE cr_return_amt_inc_tax > 100
      INTERSECT
      SELECT wr_order_number FROM web_returns WHERE wr_return_amt > 100
    ) o
  ),

  -- store return details with reason and year
  store_ret AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_returned_date_sk,
      sr.sr_net_loss,
      r.r_reason_desc,
      d.d_year
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  ),

  -- web return details with reason and year
  web_ret AS (
    SELECT
      wr.wr_order_number,
      wr.wr_returned_date_sk,
      wr.wr_net_loss,
      r.r_reason_desc AS web_reason_desc,
      d.d_year
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  ),

  -- catalog return details (includes catalog_page and ship_mode for completeness)
  catalog_ret AS (
    SELECT
      cr.cr_order_number,
      cr.cr_returned_date_sk,
      cr.cr_net_loss,
      r.r_reason_desc AS cat_reason_desc,
      d.d_year,
      cp.cp_type,
      sm.sm_carrier
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
  ),

  -- inventory linked through date (to be joined later)
  inv AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_quantity_on_hand,
      d.d_year
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
  ),

  -- full outer join of store returns and web returns on the return date
  ret_full AS (
    SELECT
      COALESCE(s.sr_ticket_number, w.wr_order_number) AS return_id,
      COALESCE(s.sr_returned_date_sk, w.wr_returned_date_sk) AS return_date_sk,
      COALESCE(s.sr_net_loss, 0) + COALESCE(w.wr_net_loss, 0) AS net_loss,
      COALESCE(s.r_reason_desc, w.web_reason_desc) AS reason_desc,
      COALESCE(s.d_year, w.d_year) AS year
    FROM store_ret s
    FULL OUTER JOIN web_ret w
      ON s.sr_returned_date_sk = w.wr_returned_date_sk
  )
SELECT
  rf.year,
  CASE
    WHEN rf.reason_desc LIKE '%product%' THEN 'Product Issue'
    ELSE 'Other'
  END AS reason_category,
  SUM(rf.net_loss) AS total_net_loss,
  COUNT(DISTINCT rf.return_id) AS distinct_return_events,
  (SELECT cnt FROM tickets_without_return) AS tickets_without_return,
  (SELECT cnt FROM common_high_value_orders) AS common_high_value_orders,
  SUM(COALESCE(i.inv_quantity_on_hand, 0)) AS total_inventory_on_return_days
FROM ret_full rf
LEFT JOIN catalog_ret cr
  ON cr.cr_returned_date_sk = rf.return_date_sk
LEFT JOIN inv i
  ON i.d_year = rf.year
GROUP BY
  rf.year,
  CASE
    WHEN rf.reason_desc LIKE '%product%' THEN 'Product Issue'
    ELSE 'Other'
  END
ORDER BY total_net_loss DESC
LIMIT 100
