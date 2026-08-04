WITH
  cr_enriched AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_item_sk,
      i.i_item_id,
      i.i_category,
      cp.cp_department,
      sm.sm_ship_mode_id,
      td.t_hour,
      cd.cd_gender,
      inv.inv_quantity_on_hand,
      inv2.inv_quantity_on_hand AS inv_quantity_on_hand_alt,
      ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY cr.cr_return_amount DESC) AS rn_category
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN inventory inv2 ON inv2.inv_item_sk = i.i_item_sk AND inv2.inv_date_sk = cr.cr_returned_date_sk
  ),
  web_enriched AS (
    SELECT
      wr.wr_order_number,
      wr.wr_return_amt,
      wr.wr_return_quantity,
      wr.wr_returned_date_sk,
      wr.wr_returned_time_sk,
      wr.wr_item_sk,
      i.i_item_id,
      i.i_category,
      cd.cd_gender,
      td.t_hour,
      inv.inv_quantity_on_hand,
      inv2.inv_quantity_on_hand AS inv_qty_alt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN inventory inv2 ON inv2.inv_item_sk = i.i_item_sk AND inv2.inv_date_sk = wr.wr_returned_date_sk
  ),
  full_joined AS (
    SELECT
      COALESCE(cr.cr_order_number, we.wr_order_number) AS order_number,
      cr.cr_return_amount,
      we.wr_return_amt,
      cr.i_category,
      we.i_category AS we_category,
      cr.rn_category,
      cr.cr_item_sk,
      we.wr_item_sk,
      cr.cr_returned_date_sk,
      we.wr_returned_date_sk
    FROM cr_enriched cr
    FULL OUTER JOIN web_enriched we
      ON cr.cr_item_sk = we.wr_item_sk
     AND cr.cr_returned_date_sk = we.wr_returned_date_sk
  ),
  intersect_items AS (
    SELECT cr_item_sk AS item_sk FROM cr_enriched
    INTERSECT
    SELECT wr_item_sk AS item_sk FROM web_enriched
  ),
  union_agg AS (
    SELECT
      cr.i_category AS category,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS cnt,
      ROW_NUMBER() OVER (PARTITION BY cr.i_category ORDER BY SUM(cr.cr_return_amount) DESC) AS rank_in_category
    FROM cr_enriched cr
    WHERE NOT EXISTS (
            SELECT 1 FROM web_returns wr
            WHERE wr.wr_order_number = cr.cr_order_number
          )
      AND cr.cr_item_sk IN (SELECT item_sk FROM intersect_items)
    GROUP BY cr.i_category
    UNION DISTINCT
    SELECT
      we.i_category AS category,
      SUM(we.wr_return_amt) AS total_return_amount,
      COUNT(*) AS cnt,
      ROW_NUMBER() OVER (PARTITION BY we.i_category ORDER BY SUM(we.wr_return_amt) DESC) AS rank_in_category
    FROM web_enriched we
    WHERE NOT EXISTS (
            SELECT 1 FROM catalog_returns cr
            WHERE cr.cr_order_number = we.wr_order_number
          )
      AND we.wr_item_sk IN (SELECT item_sk FROM intersect_items)
    GROUP BY we.i_category
  )
SELECT
  ua.category,
  ua.total_return_amount,
  ua.cnt,
  ua.rank_in_category,
  fj.order_number
FROM union_agg ua
FULL OUTER JOIN full_joined fj
  ON ua.category = fj.i_category
ORDER BY ua.total_return_amount DESC
LIMIT 100
