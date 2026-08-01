WITH
  -- Store returns with demographic and item filters
  sr AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_item_sk,
      sr.sr_return_amt,
      sr.sr_return_quantity,
      ca.ca_state,
      cd.cd_gender,
      hd.hd_vehicle_count,
      i.i_item_id,
      i.i_brand,
      i.i_size,
      d.d_year,
      d.d_date_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_size = 'small'
      AND ca.ca_state = 'CA'
  ),
  -- Web returns limited to the same year and a colour filter
  wr AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_item_sk,
      wr.wr_return_amt,
      wr.wr_return_quantity,
      d2.d_year,
      d2.d_date_sk,
      i2.i_item_id,
      i2.i_color
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
    WHERE d2.d_year = 2001
      AND i2.i_color = 'red'
  ),
  -- Inventory aggregation per item (also brings in warehouse data)
  inv_agg AS (
    SELECT
      inv.inv_item_sk,
      SUM(inv.inv_quantity_on_hand) AS total_inventory,
      COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY inv.inv_item_sk
  ),
  -- Catalog page fragment
  cp_part AS (
    SELECT
      cp.cp_catalog_page_sk,
      cp.cp_catalog_page_id,
      cp.cp_start_date_sk,
      cp.cp_end_date_sk,
      d_cp.d_date_sk AS cp_date_sk,
      d_cp.d_year
    FROM catalog_page cp
    JOIN date_dim d_cp ON cp.cp_start_date_sk = d_cp.d_date_sk
  ),
  -- Web site fragment
  ws_part AS (
    SELECT
      ws.web_site_sk,
      ws.web_site_id,
      ws.web_open_date_sk,
      d_ws.d_date_sk AS ws_date_sk,
      d_ws.d_year
    FROM web_site ws
    JOIN date_dim d_ws ON ws.web_open_date_sk = d_ws.d_date_sk
  ),
  -- Full outer join of catalog page and web site on their date keys
  cp_ws AS (
    SELECT
      cp_part.cp_catalog_page_sk,
      cp_part.cp_catalog_page_id,
      cp_part.cp_start_date_sk,
      cp_part.cp_end_date_sk,
      ws_part.web_site_sk,
      ws_part.web_site_id,
      cp_part.cp_date_sk,
      ws_part.ws_date_sk,
      COALESCE(cp_part.d_year, ws_part.d_year) AS year_key
    FROM cp_part
    FULL OUTER JOIN ws_part
      ON cp_part.cp_start_date_sk = ws_part.web_open_date_sk
  )
SELECT
  d.d_year,
  i.i_item_id,
  i.i_brand,
  SUM(sr.sr_return_amt) AS store_return_amount,
  COALESCE(SUM(wr.wr_return_amt), 0) AS web_return_amount,
  inv_agg.total_inventory,
  (
    SELECT SUM(inv2.inv_quantity_on_hand)
    FROM inventory inv2
    WHERE inv2.inv_item_sk = i.i_item_sk
  ) AS item_total_inventory,
  -- Window totals and ranking per year
  SUM(SUM(sr.sr_return_amt)) OVER (PARTITION BY d.d_year) AS yearly_store_return_total,
  RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(sr.sr_return_amt) DESC) AS store_return_rank
FROM sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN wr ON wr.wr_item_sk = i.i_item_sk
               AND wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
LEFT JOIN cp_ws ON cp_ws.cp_start_date_sk = d.d_date_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM inventory inv_chk
        WHERE inv_chk.inv_item_sk = i.i_item_sk
          AND inv_chk.inv_quantity_on_hand = 0
      )
  AND i.i_item_sk IN (
        SELECT i1.i_item_sk FROM item i1 WHERE i1.i_color = 'red'
        INTERSECT
        SELECT i2.i_item_sk FROM item i2 WHERE i2.i_size = 'small'
      )
GROUP BY
  d.d_year,
  i.i_item_id,
  i.i_brand,
  inv_agg.total_inventory,
  i.i_item_sk,
  d.d_date_sk
ORDER BY
  d.d_year DESC,
  store_return_amount DESC
LIMIT 100
