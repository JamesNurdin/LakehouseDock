WITH
  inv_sample AS (
    SELECT inv_item_sk, inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  intersect_items AS (
    SELECT inv_item_sk AS item_sk FROM inv_sample
    INTERSECT
    SELECT p_item_sk FROM promotion
  ),
  except_items AS (
    SELECT i_item_sk AS item_sk FROM item
    EXCEPT
    SELECT cr_item_sk FROM catalog_returns
  ),
  base_store AS (
    SELECT
      ss.ss_item_sk      AS ss_item_sk,
      ss.ss_store_sk     AS ss_store_sk,
      ss.ss_promo_sk     AS ss_promo_sk,
      ss.ss_addr_sk      AS ss_addr_sk,
      ss.ss_net_paid_inc_tax AS ss_net_paid_inc_tax,
      i.i_item_id,
      i.i_product_name,
      s.s_state,
      p.p_discount_active,
      ca.ca_state        AS addr_state,
      sr.sr_reason_sk,
      r.r_reason_desc
    FROM store_sales ss
    JOIN item i            ON ss.ss_item_sk = i.i_item_sk
    JOIN store s           ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p       ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r         ON sr.sr_reason_sk = r.r_reason_sk
    WHERE s.s_state = 'CA'
      AND i.i_current_price > 50
      AND p.p_discount_active = 'Y'
  ),
  base_web AS (
    SELECT
      ws.ws_item_sk       AS ws_item_sk,
      ws.ws_warehouse_sk  AS ws_warehouse_sk,
      ws.ws_ship_mode_sk  AS ws_ship_mode_sk,
      ws.ws_web_page_sk   AS ws_web_page_sk,
      ws.ws_web_site_sk   AS ws_web_site_sk,
      ws.ws_bill_addr_sk  AS ws_bill_addr_sk,
      ws.ws_net_paid_inc_tax AS ws_net_paid_inc_tax,
      i.i_item_id,
      i.i_product_name,
      sm.sm_type          AS ship_mode_type,
      w.w_state           AS warehouse_state,
      wp.wp_type          AS page_type,
      we.web_class,
      wr.wr_reason_sk,
      r2.r_reason_desc,
      ws.ws_ext_tax
    FROM web_sales ws
    JOIN item i           ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we      ON ws.ws_web_site_sk = we.web_site_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN web_returns wr  ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r2        ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE ws.ws_ext_tax > 100
      AND w.w_state = 'CA'
  )
SELECT
  COALESCE(bs.i_item_id, bw.i_item_id)                AS item_id,
  COALESCE(bs.i_product_name, bw.i_product_name)    AS product_name,
  COALESCE(bs.ss_net_paid_inc_tax, 0)               AS store_sales_amount,
  COALESCE(bw.ws_net_paid_inc_tax, 0)               AS web_sales_amount,
  COALESCE(ret.total_return_amount, 0)              AS total_catalog_return,
  (COALESCE(bs.ss_net_paid_inc_tax, 0) + COALESCE(bw.ws_net_paid_inc_tax, 0) - COALESCE(ret.total_return_amount, 0)) AS net_sales,
  RANK() OVER (ORDER BY (COALESCE(bs.ss_net_paid_inc_tax, 0) + COALESCE(bw.ws_net_paid_inc_tax, 0) - COALESCE(ret.total_return_amount, 0)) DESC) AS sales_rank
FROM base_store bs
FULL OUTER JOIN base_web bw
  ON bs.ss_item_sk = bw.ws_item_sk
JOIN intersect_items ii
  ON ii.item_sk = COALESCE(bs.ss_item_sk, bw.ws_item_sk)
LEFT JOIN LATERAL (
  SELECT SUM(cr.cr_return_amount) AS total_return_amount
  FROM catalog_returns cr
  WHERE cr.cr_item_sk = COALESCE(bs.ss_item_sk, bw.ws_item_sk)
) ret ON TRUE
LEFT JOIN except_items ei
  ON ei.item_sk = COALESCE(bs.ss_item_sk, bw.ws_item_sk)
JOIN inv_sample inv
  ON inv.inv_item_sk = COALESCE(bs.ss_item_sk, bw.ws_item_sk)
WHERE ei.item_sk IS NULL
ORDER BY net_sales DESC
LIMIT 100
