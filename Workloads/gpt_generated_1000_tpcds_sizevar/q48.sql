WITH base AS (
  SELECT
    s.s_store_id,
    i.i_category,
    ss.ss_ext_sales_price AS store_sales_amount,
    ws.ws_ext_sales_price AS web_sales_amount,
    inv.inv_quantity_on_hand,
    w.w_country,
    sm.sm_type,
    ca.ca_gmt_offset
  FROM store_sales ss
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
  LEFT JOIN web_sales ws
    ON ss.ss_item_sk = ws.ws_item_sk
  LEFT JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
  LEFT JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
  WHERE ca.ca_gmt_offset = -5.00
    AND w.w_country = 'United States'
    AND i.i_current_price > 50
    AND sm.sm_type = 'AIR'
),
sales_summary AS (
  SELECT
    s_store_id,
    i_category,
    SUM(store_sales_amount) AS total_store_sales,
    SUM(COALESCE(web_sales_amount, 0)) AS total_web_sales,
    SUM(COALESCE(inv_quantity_on_hand, 0)) AS total_inventory,
    COUNT(*) AS transaction_cnt
  FROM base
  GROUP BY s_store_id, i_category
),
high_perf AS (
  SELECT s_store_id FROM sales_summary WHERE total_store_sales > 100000
),
low_perf AS (
  SELECT s_store_id FROM sales_summary WHERE total_store_sales < 20000
)
SELECT s_store_id
FROM high_perf
EXCEPT
SELECT s_store_id FROM low_perf
ORDER BY s_store_id
LIMIT 100
