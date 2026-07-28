WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        d.d_year,
        d.d_month_seq,
        d.d_holiday,
        i.i_brand,
        i.i_category,
        s.s_store_name,
        s.s_state,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
)
SELECT
    b.s_store_name,
    b.s_state,
    b.i_brand,
    b.i_category,
    b.d_year,
    SUM(b.ss_ext_sales_price) AS total_sales,
    CASE WHEN SUM(b.ss_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'MEDIUM' END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY b.s_state ORDER BY SUM(b.ss_ext_sales_price) DESC) AS sales_rank,
    inv.inv_quantity_on_hand,
    sm.sm_type,
    cp.cp_department,
    wp.wp_type,
    ws.ws_net_profit AS web_net_profit
FROM base b
JOIN inventory inv
    ON inv.inv_item_sk = b.ss_item_sk
   AND inv.inv_date_sk = b.ss_sold_date_sk
JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = b.ss_item_sk
   AND cr.cr_returned_date_sk = b.ss_sold_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_sales ws
    ON ws.ws_item_sk = b.ss_item_sk
   AND ws.ws_sold_date_sk = b.ss_sold_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE b.d_year = 2001
  AND b.i_brand = 'Brand#12'
  AND b.s_state = 'CA'
  AND b.d_holiday = 'Y'
  AND NOT EXISTS (
      SELECT 1 FROM catalog_returns cr2 WHERE cr2.cr_order_number = b.ss_ticket_number
  )
GROUP BY
    b.s_store_name,
    b.s_state,
    b.i_brand,
    b.i_category,
    b.d_year,
    inv.inv_quantity_on_hand,
    sm.sm_type,
    cp.cp_department,
    wp.wp_type,
    ws.ws_net_profit
ORDER BY total_sales DESC
LIMIT 100
