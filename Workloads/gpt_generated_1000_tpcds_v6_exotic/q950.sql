WITH
  catalog_data AS (
    SELECT
      i.i_item_id AS item_id,
      d_sold.d_year AS year,
      cs.cs_ext_sales_price AS sales_amount,
      'catalog' AS source,
      (
        SELECT avg(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
      ) AS avg_item_sales,
      inv.inv_quantity_on_hand AS inventory_qty,
      p.p_promo_name AS promo_name,
      NULL AS reason_desc
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_warehouse_sk = w.w_warehouse_sk
                         AND inv.inv_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_current_price > 50
      AND w.w_state = 'CA'
  ),
  web_data AS (
    SELECT
      i.i_item_id AS item_id,
      d_sold.d_year AS year,
      ws.ws_ext_sales_price AS sales_amount,
      'web' AS source,
      (
        SELECT avg(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = i.i_item_sk
      ) AS avg_item_sales,
      inv.inv_quantity_on_hand AS inventory_qty,
      p.p_promo_name AS promo_name,
      r.r_reason_desc AS reason_desc
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_warehouse_sk = w.w_warehouse_sk
                         AND inv.inv_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_current_price > 50
      AND w.w_state = 'CA'
  ),
  combined AS (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM web_data
  )
SELECT
  item_id,
  year,
  source,
  sales_amount,
  avg_item_sales,
  inventory_qty,
  promo_name,
  reason_desc,
  ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY sales_amount DESC) AS sales_rank
FROM combined
ORDER BY sales_amount DESC
LIMIT 100
