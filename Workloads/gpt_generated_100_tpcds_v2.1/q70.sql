WITH overall_avg_profit AS (
    SELECT AVG(ws_net_profit) AS avg_profit
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2002
    )
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    s.s_city,
    w.w_warehouse_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    (SELECT avg_profit FROM overall_avg_profit) AS overall_avg_profit,
    CASE
        WHEN AVG(ws.ws_net_profit) > (SELECT avg_profit FROM overall_avg_profit) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM catalog_returns cr
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
    AND inv.inv_date_sk = d.d_date_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
    AND ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_order_number = ws.ws_order_number
    AND wr.wr_returned_date_sk = d.d_date_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
WHERE d.d_year = 2002
  AND hd.hd_buy_potential = '>10000'
  AND s.s_city = 'Glendale'
  AND ib.ib_upper_bound > 50000
GROUP BY
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    s.s_city,
    w.w_warehouse_name
ORDER BY total_net_profit DESC
LIMIT 100
