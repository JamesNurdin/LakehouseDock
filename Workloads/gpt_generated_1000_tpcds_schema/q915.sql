WITH
  -- Sample 10% of catalog returns to reduce data volume
  sampled_cr AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
  ),

  -- Base star‑join from catalog_returns to every other dimension table (using distinct aliases for repeated tables)
  cr_base AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_net_loss,
      i.i_item_sk,
      i.i_category,
      i.i_units,
      w.w_warehouse_sk,
      w.w_county,
      td.t_hour,
      sm.sm_ship_mode_id,
      cp.cp_department,
      hd_refunded.hd_income_band_sk,
      ca_refunded.ca_state,
      hd_returning.hd_vehicle_count,
      ca_returning.ca_city
    FROM sampled_cr cr
    JOIN catalog_page cp          ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w             ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td             ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i                  ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
  ),

  -- Inventory linked through item and warehouse (adds another join pair)
  inv_join AS (
    SELECT
      i.i_item_sk,
      w.w_warehouse_sk,
      inv.inv_quantity_on_hand
    FROM item i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w   ON inv.inv_warehouse_sk = w.w_warehouse_sk
  ),

  -- Store returns (uses the same time_dim and item joins as the star‑schema)
  sr_sub AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_return_quantity,
      sr.sr_net_loss,
      td.t_hour AS return_hour,
      w.w_warehouse_sk,
      i.i_category
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i      ON sr.sr_item_sk = i.i_item_sk
    JOIN warehouse w ON TRUE           -- keep warehouse for later full outer join
  ),

  -- Web returns (same join pattern as store_returns)
  wr_sub AS (
    SELECT
      wr.wr_item_sk,
      wr.wr_return_quantity,
      wr.wr_net_loss,
      td.t_hour AS return_hour,
      w.w_warehouse_sk,
      i.i_category
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN item i      ON wr.wr_item_sk = i.i_item_sk
    JOIN warehouse w ON TRUE
  ),

  -- Full outer join of the two return streams to keep rows that appear only in one source
  sr_wr_full AS (
    SELECT
      COALESCE(sr.sr_item_sk, wr.wr_item_sk)          AS item_sk,
      COALESCE(sr.w_warehouse_sk, wr.w_warehouse_sk) AS warehouse_sk,
      COALESCE(sr.sr_return_quantity, 0) + COALESCE(wr.wr_return_quantity, 0) AS total_return_qty,
      COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)                     AS total_net_loss
    FROM sr_sub sr
    FULL OUTER JOIN wr_sub wr
      ON sr.sr_item_sk = wr.wr_item_sk
     AND sr.w_warehouse_sk = wr.w_warehouse_sk
  ),

  -- Example of EXCEPT: items present in inventory but never returned on the web
  items_only_inventory AS (
    SELECT inv.inv_item_sk
    FROM inventory inv
    EXCEPT
    SELECT wr.wr_item_sk
    FROM web_returns wr
  ),

  -- Unnest an array of allowed units and use it in a sub‑query predicate
  allowed_units AS (
    SELECT unit
    FROM (SELECT ARRAY['Gross','Cup','Gram'] AS arr) t
    CROSS JOIN UNNEST(t.arr) AS u(unit)
  )

SELECT
  final.item_category,
  final.warehouse_county,
  SUM(final.net_loss)          AS total_net_loss,
  COUNT(DISTINCT final.item_sk) AS distinct_items,
  SUM(final.return_qty)        AS total_return_quantity
FROM (
  -- Part 1: catalog‑return rows (deduplicated by UNION DISTINCT)
  SELECT
    i.i_category AS item_category,
    w.w_county  AS warehouse_county,
    crb.cr_net_loss AS net_loss,
    crb.cr_return_quantity AS return_qty,
    i.i_item_sk AS item_sk
  FROM cr_base crb
  JOIN item i ON crb.i_item_sk = i.i_item_sk
  JOIN warehouse w ON crb.w_warehouse_sk = w.w_warehouse_sk
  WHERE i.i_units IN (SELECT unit FROM allowed_units)

  UNION DISTINCT

  -- Part 2: aggregated store/web return rows
  SELECT
    i.i_category AS item_category,
    w.w_county  AS warehouse_county,
    srw.total_net_loss AS net_loss,
    srw.total_return_qty AS return_qty,
    srw.item_sk AS item_sk
  FROM sr_wr_full srw
  JOIN item i ON srw.item_sk = i.i_item_sk
  JOIN warehouse w ON srw.warehouse_sk = w.w_warehouse_sk
  WHERE i.i_units IN (SELECT unit FROM allowed_units)
) final
GROUP BY
  final.item_category,
  final.warehouse_county
ORDER BY
  total_net_loss DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
