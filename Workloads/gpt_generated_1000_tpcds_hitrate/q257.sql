/*
Goal: Produce a deep‑join analytical query that touches all 16 selected TPC‑DS tables, re‑uses some tables under different aliases, aggregates over a CUBE of several dimensions, filters groups with HAVING, keeps only rows that have an active promotion via a correlated EXISTS, and demonstrates an INTERSECT of two key‑sets.
*/
WITH
  -- intersect the item keys that appear in both catalog_returns and web_sales
  intersect_items AS (
    SELECT cr_item_sk AS i_item_sk FROM catalog_returns
    INTERSECT
    SELECT ws_item_sk FROM web_sales
  )
SELECT
  i.i_category,
  i.i_brand,
  d_cr.d_year,
  s.s_state,
  we.web_name,
  p.p_promo_name,
  SUM(COALESCE(cr.cr_return_amount, 0))               AS total_catalog_return_amount,
  SUM(COALESCE(sr.sr_return_amt, 0))                 AS total_store_return_amount,
  SUM(COALESCE(ws.ws_net_paid, 0))                   AS total_web_sales_net_paid,
  SUM(COALESCE(wr.wr_return_amt, 0))                AS total_web_return_amount,
  SUM(COALESCE(inv.inv_quantity_on_hand, 0))        AS total_inventory_qty
FROM
  item i
  -- intersect_items restricts to items that exist in both catalog_returns and web_sales
  INNER JOIN intersect_items ii ON i.i_item_sk = ii.i_item_sk

  -- catalog_returns and its dimensions (multiple aliases for date_dim)
  LEFT JOIN catalog_returns cr          ON cr.cr_item_sk = i.i_item_sk
  LEFT JOIN date_dim d_cr               ON cr.cr_returned_date_sk = d_cr.d_date_sk
  LEFT JOIN call_center cc             ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN catalog_page cp             ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN ship_mode sm_cr             ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
  LEFT JOIN warehouse w_cr              ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
  LEFT JOIN reason r_cr                 ON cr.cr_reason_sk = r_cr.r_reason_sk

  -- store_returns and its dimensions (date_dim alias d_sr)
  LEFT JOIN store_returns sr           ON sr.sr_item_sk = i.i_item_sk
  LEFT JOIN date_dim d_sr               ON sr.sr_returned_date_sk = d_sr.d_date_sk
  LEFT JOIN store s                     ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN reason r_sr                 ON sr.sr_reason_sk = r_sr.r_reason_sk

  -- web_sales and its many dimensions (date_dim aliases d_ws_sold and d_ws_ship)
  LEFT JOIN web_sales ws               ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN date_dim d_ws_sold          ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
  LEFT JOIN date_dim d_ws_ship          ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
  LEFT JOIN web_site we                 ON ws.ws_web_site_sk = we.web_site_sk
  LEFT JOIN ship_mode sm_ws            ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  LEFT JOIN warehouse w_ws             ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
  LEFT JOIN promotion p                ON ws.ws_promo_sk = p.p_promo_sk

  -- web_returns (joined to the same web_sales order) and its dimensions
  LEFT JOIN web_returns wr            ON wr.wr_item_sk = i.i_item_sk
                                      AND wr.wr_order_number = ws.ws_order_number
  LEFT JOIN date_dim d_wr              ON wr.wr_returned_date_sk = d_wr.d_date_sk
  LEFT JOIN reason r_wr                ON wr.wr_reason_sk = r_wr.r_reason_sk

  -- inventory and its dimensions
  LEFT JOIN inventory inv              ON inv.inv_item_sk = i.i_item_sk
  LEFT JOIN date_dim d_inv              ON inv.inv_date_sk = d_inv.d_date_sk
  LEFT JOIN warehouse w_inv            ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
WHERE
  d_cr.d_year = 2000
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
      )
GROUP BY CUBE (
        i.i_category,
        i.i_brand,
        d_cr.d_year,
        s.s_state,
        we.web_name,
        p.p_promo_name
      )
HAVING
  SUM(COALESCE(ws.ws_net_paid, 0)) > 10000
