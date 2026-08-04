WITH
  agg_inventory AS (
    SELECT
      inv_item_sk,
      SUM(inv_quantity_on_hand) AS total_on_hand,
      MAX(inv_quantity_on_hand) AS max_qty
    FROM inventory
    GROUP BY inv_item_sk
  ),
  sold_items AS (
    SELECT ss_item_sk AS item_sk FROM store_sales
    UNION
    SELECT ws_item_sk FROM web_sales
  ),
  unsold_items AS (
    SELECT inv_item_sk FROM inventory
    EXCEPT
    SELECT item_sk FROM sold_items
  ),
  sampled_catalog AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_bill_hdemo_sk = 8
  )
SELECT
  i_category,
  ca_state,
  hd_buy_potential,
  cc_division_name,
  sm_type,
  promo_status,
  SUM(total_orders)               AS total_orders,
  SUM(total_sales)                AS total_sales,
  AVG(avg_sales)                  AS avg_sales,
  MIN(min_promo_cost)             AS min_promo_cost,
  MAX(has_return_reason)          AS any_return_reason,
  SUM(total_promo_adj)            AS total_promo_adj,
  SUM(unsold_flag)                AS unsold_item_cnt
FROM (
  -- Store‑sales side
  SELECT
    i.i_category                                          AS i_category,
    ca.ca_state                                           AS ca_state,
    hd.hd_buy_potential                                   AS hd_buy_potential,
    cc.cc_division_name                                   AS cc_division_name,
    sm.sm_type                                            AS sm_type,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    COUNT(DISTINCT ss.ss_ticket_number)                   AS total_orders,
    SUM(ss.ss_net_paid)                                   AS total_sales,
    AVG(ss.ss_net_paid)                                   AS avg_sales,
    MIN(p.p_cost)                                         AS min_promo_cost,
    MAX(CASE WHEN r.r_reason_desc IS NOT NULL THEN 1 ELSE 0 END) AS has_return_reason,
    SUM(lad.promo_adj)                                    AS total_promo_adj,
    CASE WHEN ui.inv_item_sk IS NOT NULL THEN 1 ELSE 0 END AS unsold_flag
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN agg_inventory inv ON i.i_item_sk = inv.inv_item_sk
  LEFT JOIN unsold_items ui ON i.i_item_sk = ui.inv_item_sk
  JOIN sampled_catalog cs ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN LATERAL (
    SELECT CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost * 0.2 ELSE 0 END AS promo_adj
  ) AS lad ON TRUE
  WHERE
    cc.cc_mkt_id = 2
    AND ca.ca_state = 'CA'
    AND i.i_brand = 'Brand#12'
    AND hd.hd_buy_potential = '0-500'
    AND inv.total_on_hand > 100
  GROUP BY
    i.i_category,
    ca.ca_state,
    hd.hd_buy_potential,
    cc.cc_division_name,
    sm.sm_type,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END,
    CASE WHEN ui.inv_item_sk IS NOT NULL THEN 1 ELSE 0 END

  UNION DISTINCT

  -- Web‑sales side
  SELECT
    i.i_category                                          AS i_category,
    ca.ca_state                                           AS ca_state,
    hd.hd_buy_potential                                   AS hd_buy_potential,
    cc.cc_division_name                                   AS cc_division_name,
    sm_ws.sm_type                                         AS sm_type,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    COUNT(DISTINCT ws.ws_order_number)                    AS total_orders,
    SUM(ws.ws_net_paid)                                   AS total_sales,
    AVG(ws.ws_net_paid)                                   AS avg_sales,
    MIN(p.p_cost)                                         AS min_promo_cost,
    MAX(CASE WHEN r_wr.r_reason_desc IS NOT NULL THEN 1 ELSE 0 END) AS has_return_reason,
    SUM(lad2.promo_adj)                                   AS total_promo_adj,
    CASE WHEN ui2.inv_item_sk IS NOT NULL THEN 1 ELSE 0 END AS unsold_flag
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
  LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
  LEFT JOIN agg_inventory inv ON i.i_item_sk = inv.inv_item_sk
  LEFT JOIN unsold_items ui2 ON i.i_item_sk = ui2.inv_item_sk
  JOIN sampled_catalog cs2 ON cs2.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs2.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  LEFT JOIN LATERAL (
    SELECT CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost * 0.2 ELSE 0 END AS promo_adj
  ) AS lad2 ON TRUE
  WHERE
    cc.cc_mkt_id = 2
    AND ca.ca_state = 'CA'
    AND i.i_brand = 'Brand#12'
    AND hd.hd_buy_potential = '0-500'
    AND inv.total_on_hand > 100
  GROUP BY
    i.i_category,
    ca.ca_state,
    hd.hd_buy_potential,
    cc.cc_division_name,
    sm_ws.sm_type,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END,
    CASE WHEN ui2.inv_item_sk IS NOT NULL THEN 1 ELSE 0 END
) AS unioned
GROUP BY
  i_category,
  ca_state,
  hd_buy_potential,
  cc_division_name,
  sm_type,
  promo_status
ORDER BY total_sales DESC
LIMIT 100
