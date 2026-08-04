WITH
  -- Base query joining all 14 tables and aggregating per store and item category
  base AS (
    SELECT
      s.s_store_id,
      i.i_category AS item_category,
      i.i_item_sk,
      SUM(ws.ws_net_profit) AS total_net_profit,
      SUM(cr.cr_return_amount) AS total_return_amount,
      d_sold.d_year
    FROM web_sales ws
      JOIN item i ON ws.ws_item_sk = i.i_item_sk
      JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
      JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
      JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
      JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
      JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
      LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
      LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
      -- Right outer join to retain every store, linking through the closed‑date key
      RIGHT JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
      -- Catalog returns linked to the same date and the same item
      JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sold.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
      JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
      JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
      JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
      JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
      -- Inventory for the same item and date
      JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
    WHERE
      d_sold.d_year = 2000
      AND s.s_state = 'CA'
      AND t_sold.t_hour BETWEEN 9 AND 17
      AND d_sold.d_weekend = 'N'
      AND cc.cc_country = 'United States'
    GROUP BY
      s.s_store_id,
      i.i_category,
      i.i_item_sk,
      d_sold.d_year
  ),
  -- Key set A: stores in California
  store_keys_a AS (
    SELECT s_store_id
    FROM store
    WHERE s_state = 'CA'
  ),
  -- Key set B: stores that closed in the year 2000 and have a tax percentage > 5
  store_keys_b AS (
    SELECT s.s_store_id
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND s.s_tax_percentage > 5.0
  ),
  -- Subtract B from A
  filtered_keys AS (
    SELECT s_store_id FROM store_keys_a
    EXCEPT
    SELECT s_store_id FROM store_keys_b
  ),
  -- Intersect A and B
  intersected_keys AS (
    SELECT s_store_id FROM store_keys_a
    INTERSECT
    SELECT s_store_id FROM store_keys_b
  )
SELECT
  b.s_store_id,
  b.item_category,
  b.total_net_profit,
  b.total_return_amount,
  -- Correlated scalar subquery: total inventory quantity for the item across all dates
  (SELECT SUM(inv2.inv_quantity_on_hand)
   FROM inventory inv2
   WHERE inv2.inv_item_sk = b.i_item_sk) AS total_inventory_qty,
  CASE WHEN b.item_category IS NOT NULL THEN 1 ELSE 0 END AS has_category_flag
FROM base b
WHERE b.s_store_id IN (SELECT s_store_id FROM filtered_keys)
  AND b.s_store_id IN (SELECT s_store_id FROM intersected_keys)
ORDER BY b.total_net_profit DESC
LIMIT 100
