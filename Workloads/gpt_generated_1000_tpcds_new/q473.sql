WITH sampled_items AS (
    SELECT i_item_sk, i_product_name, i_category
    FROM item
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    s.s_store_name,
    i.i_category,
    d_sold.d_year,
    sm_catalog.sm_type,
    SUM(ss.ss_net_profit) AS store_sales_profit,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales
FROM store_sales ss
JOIN sampled_items i
    ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
-- inventory brings a warehouse into the star
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d_sold.d_date_sk
JOIN warehouse w_inv
    ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
-- catalog returns and its related dimensions
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_returned_date_sk = d_sold.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_catalog
    ON cr.cr_ship_mode_sk = sm_catalog.sm_ship_mode_sk
JOIN warehouse w_cr
    ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
-- web sales and its related dimensions
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN ship_mode sm_web
    ON ws.ws_ship_mode_sk = sm_web.sm_ship_mode_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN web_site web_site_ws
    ON ws.ws_web_site_sk = web_site_ws.web_site_sk
-- web returns linked to web sales
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
WHERE ss.ss_item_sk NOT IN (
    SELECT cr2.cr_item_sk
    FROM catalog_returns cr2
    WHERE cr2.cr_returned_date_sk = d_sold.d_date_sk
)
GROUP BY CUBE (s.s_store_name, i.i_category, d_sold.d_year, sm_catalog.sm_type)
ORDER BY store_sales_profit DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
