WITH
joined_all AS (
   SELECT
      cr.cr_returned_date_sk AS cr_date_sk,
      cr.cr_return_quantity AS cr_return_qty,
      cr.cr_return_amount AS cr_return_amount,
      cr.cr_return_tax AS cr_return_tax,
      cr.cr_return_ship_cost AS cr_return_ship_cost,
      cr.cr_refunded_cash AS cr_refunded_cash,
      cr.cr_net_loss AS cr_net_loss,
      ca_refund.ca_zip AS ca_refund_zip,
      ca_refund.ca_state AS ca_refund_state,
      cc.cc_call_center_id,
      cc.cc_name,
      i.i_item_sk,
      i.i_item_id,
      i.i_category,
      i.i_brand,
      i.i_current_price,
      p.p_promo_id,
      p.p_discount_active,
      inv.inv_quantity_on_hand,
      d_ret.d_year,
      s.s_store_id,
      s.s_state,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_return_tax,
      sr.sr_return_ship_cost,
      sr.sr_refunded_cash,
      sr.sr_net_loss,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_return_tax,
      wr.wr_return_ship_cost,
      wr.wr_refunded_cash,
      wr.wr_net_loss,
      wp.wp_url
   FROM catalog_returns cr
   INNER JOIN date_dim d_ret
       ON cr.cr_returned_date_sk = d_ret.d_date_sk
   INNER JOIN item i
       ON cr.cr_item_sk = i.i_item_sk
   INNER JOIN customer_address ca_refund
       ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
   INNER JOIN call_center cc
       ON cr.cr_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN promotion p
       ON p.p_item_sk = i.i_item_sk
   LEFT JOIN inventory inv
       ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_date_sk = d_ret.d_date_sk
   LEFT JOIN store_returns sr
       ON sr.sr_item_sk = i.i_item_sk
       AND sr.sr_returned_date_sk = d_ret.d_date_sk
   LEFT JOIN store s
       ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN web_returns wr
       ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_returned_date_sk = d_ret.d_date_sk
   LEFT JOIN web_page wp
       ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE d_ret.d_year = 1998
     AND ca_refund.ca_zip = '85709'
     AND i.i_current_price > 20.00
),

high_loss_items AS (
   SELECT i_item_sk
   FROM joined_all
   GROUP BY i_item_sk
   HAVING SUM(cr_net_loss + sr_net_loss + wr_net_loss) > 10000
),

active_promo_items AS (
   SELECT i.i_item_sk
   FROM promotion p
   JOIN item i ON p.p_item_sk = i.i_item_sk
   WHERE p.p_discount_active = 'Y'
     AND p.p_cost < 150.00
),

promo_and_loss_items AS (
   SELECT i_item_sk FROM high_loss_items
   INTERSECT
   SELECT i_item_sk FROM active_promo_items
),

total_inventory_qty AS (
   SELECT SUM(inv_quantity_on_hand) AS total_qty
   FROM inventory inv
   JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
   WHERE d_inv.d_year = 1998
)

SELECT
   ja.d_year,
   ja.i_category,
   ja.i_brand,
   SUM(ja.cr_return_amount) AS total_catalog_return_amount,
   SUM(ja.sr_return_amt) AS total_store_return_amount,
   SUM(ja.wr_return_amt) AS total_web_return_amount,
   SUM(ja.cr_net_loss + ja.sr_net_loss + ja.wr_net_loss) AS total_net_loss,
   COUNT(DISTINCT ja.i_item_id) AS distinct_items,
   (SELECT total_qty FROM total_inventory_qty) AS total_inventory_quantity
FROM joined_all ja
JOIN promo_and_loss_items pli
   ON ja.i_item_sk = pli.i_item_sk
GROUP BY GROUPING SETS (
   (ja.d_year, ja.i_category, ja.i_brand),
   (ja.d_year, ja.i_category),
   (ja.d_year),
   ()
)
ORDER BY ja.d_year DESC, total_catalog_return_amount DESC
LIMIT 100
