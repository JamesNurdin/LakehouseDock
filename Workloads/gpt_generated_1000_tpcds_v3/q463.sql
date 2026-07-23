WITH joined_data AS (
    SELECT
        d.d_year,
        i.i_item_id,
        i.i_product_name,
        s.s_store_name,
        sm.sm_type,
        p.p_discount_active,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_ext_ship_cost,
        sr.sr_return_amt_inc_tax,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        c.c_customer_id
    FROM tpcds.date_dim d
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    -- Join store first (using its closed date surrogate key)
    JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    -- Store returns
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
        AND sr.sr_store_sk = s.s_store_sk
    -- Catalog returns
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    -- Inventory
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND p.p_promo_name = 'anti'
)
SELECT
    d_year,
    i_item_id,
    s_store_name,
    sm_type,
    SUM(ws_ext_sales_price) AS total_web_sales,
    SUM(sr_return_amt_inc_tax) AS total_store_returns,
    SUM(cr_return_amount) AS total_catalog_returns,
    SUM(inv_quantity_on_hand) AS total_inventory,
    AVG(ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    SUM(CASE WHEN p_discount_active = 'Y' THEN ws_ext_sales_price ELSE 0 END) AS active_promo_sales,
    SUM(CASE WHEN p_discount_active = 'N' THEN ws_ext_sales_price ELSE 0 END) AS inactive_promo_sales
FROM joined_data
GROUP BY
    d_year,
    i_item_id,
    s_store_name,
    sm_type
ORDER BY total_web_sales DESC
LIMIT 100
