WITH
  ss_data AS (
    SELECT
      s.s_store_name            AS store_name,
      i.i_item_id               AS item_id,
      p.p_promo_name            AS promo_name,
      ss.ss_net_paid            AS net_paid,
      CASE
        WHEN i.i_current_price > (SELECT avg(i2.i_current_price) FROM item i2) THEN 'Above Avg'
        ELSE 'Below Avg'
      END                      AS price_category,
      s.s_state                 AS store_state,
      i.i_category              AS item_category,
      p.p_promo_id              AS promo_id
    FROM store_sales ss
      JOIN store s               ON ss.ss_store_sk = s.s_store_sk
      JOIN item i                ON ss.ss_item_sk = i.i_item_sk
      JOIN promotion p           ON ss.ss_promo_sk = p.p_promo_sk
      JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
      JOIN customer_address ca   ON ss.ss_addr_sk = ca.ca_address_sk
      FULL OUTER JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
      LEFT JOIN reason r         ON sr.sr_reason_sk = r.r_reason_sk
      LEFT JOIN inventory inv    ON i.i_item_sk = inv.inv_item_sk
  ),
  cs_data AS (
    SELECT
      cc.cc_name                AS store_name,
      i2.i_item_id              AS item_id,
      p2.p_promo_name           AS promo_name,
      cs.cs_ext_sales_price     AS net_paid,
      CASE
        WHEN i2.i_current_price > (SELECT avg(i3.i_current_price) FROM item i3) THEN 'Above Avg'
        ELSE 'Below Avg'
      END                      AS price_category,
      cc.cc_state               AS store_state,
      i2.i_category             AS item_category,
      p2.p_promo_id             AS promo_id
    FROM catalog_sales cs
      JOIN item i2                ON cs.cs_item_sk = i2.i_item_sk
      JOIN promotion p2           ON cs.cs_promo_sk = p2.p_promo_sk
      JOIN call_center cc         ON cs.cs_call_center_sk = cc.cc_call_center_sk
      JOIN catalog_page cp        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN warehouse w2           ON cs.cs_warehouse_sk = w2.w_warehouse_sk
      LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
      LEFT JOIN reason r2          ON cr.cr_reason_sk = r2.r_reason_sk
      LEFT JOIN inventory inv2    ON i2.i_item_sk = inv2.inv_item_sk AND w2.w_warehouse_sk = inv2.inv_warehouse_sk
  ),
  ws_data AS (
    SELECT
      w3.w_warehouse_name       AS store_name,
      i3.i_item_id              AS item_id,
      p3.p_promo_name           AS promo_name,
      ws.ws_ext_sales_price     AS net_paid,
      CASE
        WHEN i3.i_current_price > (SELECT avg(i4.i_current_price) FROM item i4) THEN 'Above Avg'
        ELSE 'Below Avg'
      END                      AS price_category,
      w3.w_state                AS store_state,
      i3.i_category             AS item_category,
      p3.p_promo_id             AS promo_id
    FROM web_sales ws
      JOIN item i3                ON ws.ws_item_sk = i3.i_item_sk
      JOIN promotion p3           ON ws.ws_promo_sk = p3.p_promo_sk
      JOIN warehouse w3           ON ws.ws_warehouse_sk = w3.w_warehouse_sk
      LEFT JOIN web_returns wr   ON ws.ws_order_number = wr.wr_order_number
      LEFT JOIN reason r3        ON wr.wr_reason_sk = r3.r_reason_sk
  ),
  union_all AS (
    SELECT store_name, item_id, promo_name, net_paid, price_category, store_state, item_category, promo_id FROM ss_data
    UNION
    SELECT store_name, item_id, promo_name, net_paid, price_category, store_state, item_category, promo_id FROM cs_data
    UNION
    SELECT store_name, item_id, promo_name, net_paid, price_category, store_state, item_category, promo_id FROM ws_data
  ),
  intersect_set AS (
    SELECT store_name, item_id, promo_name, net_paid, price_category, store_state, item_category, promo_id
    FROM ss_data
    WHERE net_paid > 1000
  ),
  exclude_set AS (
    SELECT store_name, item_id, promo_name, net_paid, price_category, store_state, item_category, promo_id
    FROM cs_data
    WHERE price_category = 'Below Avg'
  )
SELECT
  store_name,
  item_id,
  promo_name,
  store_state,
  item_category,
  SUM(net_paid)                AS total_net_paid,
  COUNT(*)                     AS txn_count,
  CASE WHEN SUM(net_paid) > 10000 THEN 'High' ELSE 'Low' END AS volume_flag
FROM (
  (SELECT * FROM union_all)
  INTERSECT
  (SELECT * FROM intersect_set)
  EXCEPT
  (SELECT * FROM exclude_set)
) AS final_set
GROUP BY CUBE (store_name, item_id, promo_name, store_state, item_category)
HAVING SUM(net_paid) > 0
ORDER BY total_net_paid DESC
LIMIT 100
