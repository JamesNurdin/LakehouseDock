WITH
  ss_base AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_cdemo_sk,
      ss.ss_promo_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      i.i_category,
      i.i_item_id,
      p.p_promo_name,
      s.s_store_name,
      cd.cd_gender,
      t.t_hour
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'F'
      AND ss.ss_quantity > 1
  ),
  cs_base AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_net_paid,
      cp.cp_type,
      cc.cc_name,
      p.p_promo_name
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cp.cp_type = 'monthly'
      AND cc.cc_state = 'CA'
      AND cs.cs_quantity > 2
  ),
  ws_base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_item_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      wp.wp_max_ad_count,
      p.p_promo_name
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE wp.wp_max_ad_count >= 2
      AND ws.ws_quantity > 0
  ),
  inv_base AS (
    SELECT inv.inv_item_sk, inv.inv_quantity_on_hand
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 0
  ),
  sr_base AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_return_quantity,
      sr.sr_net_loss
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
  ),
  ticket_intersect AS (
    SELECT ss_ticket_number FROM store_sales
    INTERSECT
    SELECT sr_ticket_number FROM store_returns
  ),
  ticket_except AS (
    SELECT ss_ticket_number FROM store_sales
    EXCEPT
    SELECT sr_ticket_number FROM store_returns
  )
SELECT
  ss.s_store_name,
  ss.i_category,
  ss.p_promo_name,
  COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
  SUM(ss.ss_net_paid) AS total_net_paid,
  AVG(ss.ss_quantity) AS avg_quantity,
  MIN(ss.ss_net_paid) AS min_net_paid,
  MAX(ss.ss_net_paid) AS max_net_paid,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
  COUNT(DISTINCT ws.ws_order_number) AS web_orders,
  SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
  COUNT(DISTINCT sr.sr_ticket_number) FILTER (WHERE sr.sr_ticket_number IN (SELECT ss_ticket_number FROM ticket_intersect)) AS returns_intersect_count,
  COUNT(DISTINCT sr.sr_ticket_number) FILTER (WHERE sr.sr_ticket_number IN (SELECT ss_ticket_number FROM ticket_except)) AS returns_except_count
FROM ss_base ss
LEFT JOIN cs_base cs ON cs.cs_item_sk = ss.ss_item_sk
LEFT JOIN ws_base ws ON ws.ws_item_sk = ss.ss_item_sk
LEFT JOIN inv_base inv ON inv.inv_item_sk = ss.ss_item_sk
LEFT JOIN sr_base sr ON sr.sr_ticket_number = ss.ss_ticket_number
WHERE ss.ss_ticket_number IN (SELECT ss_ticket_number FROM ticket_intersect)
GROUP BY
  ss.s_store_name,
  ss.i_category,
  ss.p_promo_name
ORDER BY total_net_paid DESC
LIMIT 100
