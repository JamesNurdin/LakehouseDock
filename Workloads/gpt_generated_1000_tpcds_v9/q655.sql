WITH joined_data AS (
    SELECT
        d_sale.d_year AS sale_year,
        i.i_category,
        i.i_brand,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_quantity,
        i.i_current_price,
        sm.sm_type AS ship_mode_type,
        p.p_promo_name,
        cc.cc_name AS call_center_name,
        cp.cp_department,
        r.r_reason_desc,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cust.c_first_name,
        cust.c_last_name,
        cd.cd_gender,
        hd.hd_vehicle_count,
        ca.ca_city,
        ca.ca_state,
        store.s_store_name,
        store.s_state,
        wh.w_warehouse_name,
        wp.wp_url
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d_sale
        ON ws.ws_sold_date_sk = d_sale.d_date_sk
    JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.customer cust
        ON ws.ws_bill_customer_sk = cust.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.store
        ON store.s_closed_date_sk = d_sale.d_date_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d_sale.d_date_sk
    LEFT JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d_sale.d_date >= DATE '1998-01-01'
      AND d_sale.d_year BETWEEN 1998 AND 2000
      AND i.i_category = 'Electronics'
      AND store.s_state = 'CA'
)
SELECT
    sale_year,
    i_category,
    i_brand,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(cr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT ws_order_number) AS num_orders,
    AVG(i_current_price) AS avg_item_price,
    (SELECT AVG(ws2.ws_ext_sales_price) FROM tpcds.web_sales ws2) AS overall_avg_sales_price
FROM joined_data
GROUP BY sale_year, i_category, i_brand
HAVING SUM(ws_ext_sales_price) > (SELECT AVG(ws2.ws_ext_sales_price) FROM tpcds.web_sales ws2) * 10
   AND SUM(COALESCE(cr_return_amount, 0)) < 50000
   AND COUNT(DISTINCT ws_order_number) >= 1000
ORDER BY total_sales DESC
LIMIT 100
