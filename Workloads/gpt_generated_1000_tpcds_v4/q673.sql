WITH catalog_fact AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reason_sk
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
        AND cs.cs_ship_mode_sk = cr.cr_ship_mode_sk
        AND cs.cs_warehouse_sk = cr.cr_warehouse_sk
        AND cs.cs_sold_time_sk = cr.cr_returned_time_sk
    WHERE cs.cs_sold_time_sk IN (
        SELECT t_time_sk FROM time_dim
        WHERE t_time = 14
          AND t_sub_shift = 'morning'
    )
      AND cs.cs_ship_mode_sk IN (
        SELECT sm_ship_mode_sk FROM ship_mode
        WHERE sm_type = 'AIR'
          AND sm_carrier = 'UPS'
      )
      AND cs.cs_warehouse_sk IN (
        SELECT w_warehouse_sk FROM warehouse
        WHERE w_state = 'CA'
          AND w_gmt_offset = -5.00
      )
)
SELECT
    td.t_hour,
    sm.sm_ship_mode_id,
    wh.w_warehouse_name,
    ws_site.web_city,
    wp.wp_type,
    SUM(cf.cs_net_paid) AS total_catalog_sales,
    SUM(COALESCE(cf.cr_return_amount, 0)) AS total_catalog_returns,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_returns,
    COUNT(DISTINCT cf.cs_order_number) AS distinct_orders
FROM catalog_fact cf
JOIN time_dim td
    ON cf.cs_sold_time_sk = td.t_time_sk
JOIN ship_mode sm
    ON cf.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse wh
    ON cf.cs_warehouse_sk = wh.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   AND ws.ws_warehouse_sk = wh.w_warehouse_sk
   AND ws.ws_sold_time_sk = td.t_time_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_web_page_sk = wp.wp_web_page_sk
   AND wr.wr_order_number = ws.ws_order_number
   AND wr.wr_returned_time_sk = td.t_time_sk
WHERE ws_site.web_city = 'Harmony'
  AND wp.wp_type = 'product'
  AND td.t_time IN (14, 10)
  AND sm.sm_code = 'SM01'
GROUP BY
    td.t_hour,
    sm.sm_ship_mode_id,
    wh.w_warehouse_name,
    ws_site.web_city,
    wp.wp_type
ORDER BY total_catalog_sales DESC
LIMIT 100
