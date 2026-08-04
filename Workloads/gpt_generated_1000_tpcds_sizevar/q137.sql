WITH
    item_dim AS (
        SELECT i_item_sk, i_product_name, i_category, i_brand
        FROM item
    ),
    customer_dim AS (
        SELECT c_customer_sk, c_first_name, c_last_name, c_email_address, c_current_addr_sk
        FROM customer
    ),
    address_dim AS (
        SELECT ca_address_sk, ca_city, ca_state, ca_zip
        FROM customer_address
    ),
    store_dim AS (
        SELECT s_store_sk, s_store_name, s_state
        FROM store
    ),
    promo_dim AS (
        SELECT p_promo_sk,
               p_promo_name,
               ARRAY[p_channel_tv, p_channel_email, p_channel_dmail] AS promo_channels,
               p_discount_active
        FROM promotion
    ),
    reason_dim AS (
        SELECT r_reason_sk, r_reason_desc
        FROM reason
    ),
    ship_mode_dim AS (
        SELECT sm_ship_mode_sk, sm_type, sm_carrier
        FROM ship_mode
    ),
    call_center_dim AS (
        SELECT cc_call_center_sk, cc_name, cc_market_manager
        FROM call_center
    ),
    catalog_page_dim AS (
        SELECT cp_catalog_page_sk, cp_catalog_number, cp_department
        FROM catalog_page
    )
SELECT
    i.i_item_sk,
    i.i_product_name,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank,
    pc.promo_channel
FROM
    store_sales ss
    JOIN item_dim i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_dim c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN address_dim a ON ss.ss_addr_sk = a.ca_address_sk
    JOIN store_dim s ON ss.ss_store_sk = s.s_store_sk
    JOIN promo_dim p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN LATERAL (
        SELECT elem AS promo_channel
        FROM UNNEST(p.promo_channels) AS t(elem)
        LIMIT 1
    ) pc ON true
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page_dim cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center_dim cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode_dim sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN reason_dim r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
WHERE
    a.ca_state = 'CA'
GROUP BY
    i.i_item_sk,
    i.i_product_name,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END,
    pc.promo_channel
ORDER BY
    total_store_sales DESC
LIMIT 100
