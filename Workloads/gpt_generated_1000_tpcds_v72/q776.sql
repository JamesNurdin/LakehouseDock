WITH
  base AS (
    SELECT
      t.t_hour,
      i.i_category,
      w.w_warehouse_name,
      cc.cc_name,
      cp.cp_type,
      cs.cs_ext_sales_price,
      ss.ss_ext_sales_price,
      ws.ws_ext_sales_price,
      cs.cs_order_number,
      ss.ss_ticket_number,
      ws.ws_order_number,
      cs.cs_ext_discount_amt,
      inv.inv_quantity_on_hand,
      cc.cc_state,
      i.i_brand,
      cp.cp_type AS cp_type_filter,
      sm.sm_code,
      w.w_city
    FROM catalog_sales cs
      JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
      JOIN item i ON cs.cs_item_sk = i.i_item_sk
      JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
      JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
      JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
      JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
      JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
      JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
      LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
      LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
      JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
      JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_time_sk = t.t_time_sk
      JOIN store s ON ss.ss_store_sk = s.s_store_sk
      JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_time_sk = t.t_time_sk
      JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
      LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i.i_item_sk
  )
,
  agg_a AS (
    SELECT
      t_hour,
      i_category,
      w_warehouse_name,
      cc_name,
      cp_type,
      SUM(cs_ext_sales_price)               AS total_catalog_sales,
      SUM(ss_ext_sales_price)               AS total_store_sales,
      SUM(ws_ext_sales_price)               AS total_web_sales,
      COUNT(DISTINCT cs_order_number)       AS catalog_order_cnt,
      COUNT(DISTINCT ss_ticket_number)      AS store_ticket_cnt,
      COUNT(DISTINCT ws_order_number)       AS web_order_cnt,
      AVG(cs_ext_discount_amt)              AS avg_catalog_discount
    FROM base
    WHERE
      cc_state = 'CA'               AND
      i_brand = 'Brand#12'          AND
      cp_type_filter = 'PROMO'      AND
      sm_code = 'AIR'               AND
      w_city = 'Seattle'            AND
      inv_quantity_on_hand > 100
    GROUP BY GROUPING SETS (
      (t_hour, i_category),
      (w_warehouse_name),
      (cc_name, cp_type),
      ()
    )
  ),
  agg_b AS (
    SELECT
      t_hour,
      i_category,
      w_warehouse_name,
      cc_name,
      cp_type,
      SUM(cs_ext_sales_price)               AS total_catalog_sales,
      SUM(ss_ext_sales_price)               AS total_store_sales,
      SUM(ws_ext_sales_price)               AS total_web_sales,
      COUNT(DISTINCT cs_order_number)       AS catalog_order_cnt,
      COUNT(DISTINCT ss_ticket_number)      AS store_ticket_cnt,
      COUNT(DISTINCT ws_order_number)       AS web_order_cnt,
      AVG(cs_ext_discount_amt)              AS avg_catalog_discount
    FROM base
    WHERE
      cc_state = 'TX'               AND
      i_brand = 'Brand#34'          AND
      cp_type_filter = 'STANDARD'   AND
      sm_code = 'SEA'               AND
      w_city = 'New York'           AND
      inv_quantity_on_hand > 200
    GROUP BY GROUPING SETS (
      (t_hour, i_category),
      (w_warehouse_name),
      (cc_name, cp_type),
      ()
    )
  )
SELECT *
FROM (
  SELECT * FROM agg_a
  UNION ALL
  SELECT * FROM agg_b
) AS final_result
ORDER BY total_catalog_sales DESC, total_web_sales DESC
LIMIT 100
