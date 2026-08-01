WITH sales_data AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        i.i_item_sk,
        i.i_product_name,
        d.d_year,
        p.p_promo_id,
        cc.cc_name,
        sm.sm_type,
        w.w_warehouse_name,
        wsite.web_site_id,
        SUM(cs.cs_net_paid) AS sum_catalog_net_paid,
        SUM(ss.ss_net_paid) AS sum_store_net_paid,
        SUM(ws.ws_net_paid) AS sum_web_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS cnt_orders,
        SUM(inv.inv_quantity_on_hand) AS sum_quantity_on_hand
    FROM
        catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk AND ss.ss_item_sk = i.i_item_sk AND ss.ss_customer_sk = c.c_customer_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        d.d_year = 2001
        AND i.i_brand = 'Brand#12'
        AND cc.cc_state = 'CA'
        AND p.p_channel_email = 'Y'
        AND sm.sm_type = 'AIR'
        AND c.c_preferred_cust_flag = 'Y'
        AND NOT EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_returning_customer_sk = c.c_customer_sk
              AND wr.wr_returned_date_sk = d.d_date_sk
        )
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        i.i_item_sk,
        i.i_product_name,
        d.d_year,
        p.p_promo_id,
        cc.cc_name,
        sm.sm_type,
        w.w_warehouse_name,
        wsite.web_site_id
)
SELECT
    c_customer_id,
    i_product_name,
    d_year,
    cc_name,
    sm_type,
    w_warehouse_name,
    web_site_id,
    sum_catalog_net_paid,
    sum_store_net_paid,
    sum_web_net_paid,
    sum_quantity_on_hand,
    cnt_orders,
    (sum_catalog_net_paid + sum_store_net_paid + sum_web_net_paid) AS total_sales,
    RANK() OVER (ORDER BY (sum_catalog_net_paid + sum_store_net_paid + sum_web_net_paid) DESC) AS sales_rank,
    SUM((sum_catalog_net_paid + sum_store_net_paid + sum_web_net_paid)) OVER (PARTITION BY c_customer_id) AS cust_total_sales
FROM
    sales_data
ORDER BY
    total_sales DESC
LIMIT 100
