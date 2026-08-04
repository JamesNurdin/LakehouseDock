WITH filtered_store AS (
    SELECT s.*
    FROM store s
    WHERE s.s_division_id = 1
      AND s.s_store_sk IN (SELECT sr2.sr_store_sk FROM store_returns sr2 WHERE sr2.sr_return_quantity > 10)
),
item_filtered AS (
    SELECT i.*
    FROM item i
    WHERE i.i_brand_id = 5
),
promo_filtered AS (
    SELECT p.*
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
)
SELECT
    s.s_store_id,
    s.s_store_name,
    SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
    CASE WHEN SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) > 0 THEN 'Loss' ELSE 'Profit' END AS loss_status,
    RANK() OVER (ORDER BY SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) DESC) AS loss_rank,
    lp.latest_promo_cost
FROM filtered_store s
JOIN store_sales ss
  ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim td
  ON ss.ss_sold_time_sk = td.t_time_sk
     AND td.t_hour BETWEEN 9 AND 17
JOIN item_filtered i
  ON ss.ss_item_sk = i.i_item_sk
JOIN promo_filtered p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_store_sk = s.s_store_sk
     AND sr.sr_cdemo_sk = cd.cd_demo_sk
     AND sr.sr_addr_sk = ca.ca_address_sk
     AND sr.sr_return_time_sk = td.t_time_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
     AND cr.cr_returned_time_sk = td.t_time_sk
     AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
     AND cr.cr_refunded_addr_sk = ca.ca_address_sk
     AND cr.cr_returning_cdemo_sk = cd.cd_demo_sk
     AND cr.cr_returning_addr_sk = ca.ca_address_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
CROSS JOIN LATERAL (
    SELECT p2.p_cost AS latest_promo_cost
    FROM promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
    ORDER BY p2.p_start_date_sk DESC
    LIMIT 1
) lp
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
     AND inv.inv_quantity_on_hand > 0
     -- sample 10 % of inventory rows
     -- Trino syntax for bernoulli sampling
     
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_sold_time_sk = td.t_time_sk
     AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
     AND ws.ws_bill_addr_sk = ca.ca_address_sk
     AND ws.ws_ship_cdemo_sk = cd.cd_demo_sk
     AND ws.ws_ship_addr_sk = ca.ca_address_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
     AND wr.wr_returned_time_sk = td.t_time_sk
     AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
     AND wr.wr_refunded_addr_sk = ca.ca_address_sk
     AND wr.wr_returning_cdemo_sk = cd.cd_demo_sk
     AND wr.wr_returning_addr_sk = ca.ca_address_sk
     AND wr.wr_web_page_sk = wp.wp_web_page_sk
     AND wr.wr_order_number = ws.ws_order_number
GROUP BY
    s.s_store_id,
    s.s_store_name,
    lp.latest_promo_cost
ORDER BY loss_rank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
