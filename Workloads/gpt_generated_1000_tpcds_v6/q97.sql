WITH joined_data AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        ca.ca_state,
        sm.sm_type,
        we.web_name,
        ss.ss_ticket_number AS store_ticket,
        ws.ws_order_number AS web_order,
        ss.ss_ext_sales_price AS store_sales_amount,
        ws.ws_ext_sales_price AS web_sales_amount,
        cr.cr_return_amount AS catalog_return_amount,
        wr.wr_return_amt AS web_return_amount,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND ca.ca_city = 'Pleasant Valley'
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND we.web_name = 'SiteA'
      AND cc.cc_name = 'Call Center 1'
)
SELECT
    d_year,
    i_category,
    i_brand,
    ca_state,
    sm_type,
    web_name,
    SUM(store_sales_amount) AS total_store_sales,
    SUM(web_sales_amount) AS total_web_sales,
    SUM(catalog_return_amount) AS total_catalog_returns,
    SUM(web_return_amount) AS total_web_returns,
    COUNT(DISTINCT store_ticket) AS distinct_store_orders,
    COUNT(DISTINCT web_order) AS distinct_web_orders,
    MIN(inv_quantity_on_hand) AS min_inventory_on_hand,
    MAX(inv_quantity_on_hand) AS max_inventory_on_hand
FROM joined_data
GROUP BY d_year, i_category, i_brand, ca_state, sm_type, web_name
ORDER BY total_store_sales DESC
LIMIT 100
