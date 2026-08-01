WITH
  catalog_branch AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_bill_customer_sk,
      cs.cs_item_sk,
      cs.cs_net_profit,
      c.c_first_name,
      c.c_last_name,
      i.i_category,
      i.i_brand,
      cc.cc_manager,
      cp.cp_catalog_page_id,
      sm.sm_type,
      p.p_promo_id,
      td.t_hour,
      cr.cr_return_quantity,
      r.r_reason_desc,
      inv.inv_quantity_on_hand
    FROM catalog_sales cs
      JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
      JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
      JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
      JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
      JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN item i ON cs.cs_item_sk = i.i_item_sk
      JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
      LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = cs.cs_item_sk
      LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
      LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE cc.cc_country = 'United States'
      AND p.p_channel_radio = 'N'
      AND cp.cp_end_date_sk > 2451000
      AND i.i_brand = 'BrandX'
      AND td.t_hour BETWEEN 9 AND 17
      AND cc.cc_manager = 'Roderick Walls'
  ),
  web_branch AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_bill_customer_sk,
      ws.ws_item_sk,
      ws.ws_net_profit,
      c.c_first_name,
      c.c_last_name,
      i.i_category,
      i.i_brand,
      wp.wp_url,
      sm.sm_type,
      p.p_promo_id,
      td.t_hour,
      wr.wr_return_quantity,
      r.r_reason_desc,
      inv.inv_quantity_on_hand
    FROM web_sales ws
      JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
      JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
      JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
      JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
      JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
      JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN item i ON ws.ws_item_sk = i.i_item_sk
      JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
      LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk = i.i_item_sk
      LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
      LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE we.web_country = 'United States'
      AND p.p_channel_radio = 'N'
      AND wp.wp_type = 'home'
      AND i.i_category = 'Electronics'
      AND td.t_hour BETWEEN 9 AND 17
      AND wp.wp_url LIKE 'http%'
  ),
  union_all_sales AS (
    SELECT
      cs_sold_date_sk        AS sold_date_sk,
      cs_sold_time_sk        AS sold_time_sk,
      cs_bill_customer_sk    AS customer_sk,
      cs_item_sk             AS item_sk,
      cs_net_profit          AS net_profit,
      CASE WHEN cs_net_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag,
      cc_manager,
      i_category,
      i_brand,
      cp_catalog_page_id    AS page_id,
      sm_type,
      p_promo_id,
      t_hour,
      inv_quantity_on_hand
    FROM catalog_branch
    UNION DISTINCT
    SELECT
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_bill_customer_sk,
      ws_item_sk,
      ws_net_profit,
      CASE WHEN ws_net_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END,
      NULL AS cc_manager,
      i_category,
      i_brand,
      wp_url AS page_id,
      sm_type,
      p_promo_id,
      t_hour,
      inv_quantity_on_hand
    FROM web_branch
  ),
  agg1 AS (
    SELECT
      customer_sk,
      i_category,
      SUM(net_profit)                         AS total_profit,
      COUNT(*)                                 AS txn_count,
      AVG(net_profit)                         AS avg_profit,
      SUM(CASE WHEN profit_flag = 'POSITIVE' THEN net_profit ELSE 0 END) AS pos_profit
    FROM union_all_sales
    GROUP BY GROUPING SETS (
      (customer_sk, i_category),
      (customer_sk),
      (i_category)
    )
  ),
  filtered_agg AS (
    SELECT *
    FROM agg1
    WHERE total_profit > 10000
      AND txn_count >= 5
      AND avg_profit > 0
      AND pos_profit > 5000
      AND customer_sk IS NOT NULL
      AND i_category IS NOT NULL
  ),
  set_a AS (
    SELECT customer_sk FROM filtered_agg WHERE total_profit > 20000
  ),
  set_b AS (
    SELECT customer_sk FROM filtered_agg WHERE txn_count > 10
  ),
  intersect_set AS (
    SELECT customer_sk FROM set_a
    INTERSECT
    SELECT customer_sk FROM set_b
  ),
  except_set AS (
    SELECT customer_sk FROM set_a
    EXCEPT
    SELECT customer_sk FROM set_b
  )
SELECT
  f.customer_sk,
  f.i_category,
  f.total_profit,
  f.txn_count,
  f.avg_profit,
  (
    SELECT COUNT(*)
    FROM catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = f.customer_sk
  ) AS total_orders_corr
FROM filtered_agg f
WHERE f.customer_sk IN (SELECT customer_sk FROM intersect_set)
  AND f.customer_sk NOT IN (SELECT customer_sk FROM except_set)
ORDER BY f.total_profit DESC
LIMIT 100
