WITH
    filtered_item AS (
        SELECT i_item_sk, i_item_id, i_product_name, i_current_price, i_brand
        FROM item
        WHERE i_current_price > 150.00
          AND i_brand = 'Brand#23'
    ),
    filtered_store AS (
        SELECT s_store_sk, s_store_name, s_state
        FROM store
        WHERE s_state = 'CA'
    ),
    filtered_promo AS (
        SELECT p_promo_sk, p_promo_name, p_discount_active
        FROM promotion
        WHERE p_discount_active = 'Y'
    ),
    filtered_hd AS (
        SELECT hd_demo_sk, hd_buy_potential
        FROM household_demographics
        WHERE hd_buy_potential = '5000-9999'
    ),
    filtered_reason AS (
        SELECT r_reason_sk, r_reason_desc
        FROM reason
        WHERE r_reason_desc = 'Damaged'
    ),
    filtered_inventory AS (
        SELECT inv_item_sk, inv_quantity_on_hand
        FROM inventory
        WHERE inv_quantity_on_hand > 0
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    s.s_state,
    hd.hd_buy_potential,
    p.p_promo_name,
    r.r_reason_desc,
    wsit.web_name,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(wr.wr_return_amt) AS total_web_returns,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_sales_transactions
FROM filtered_item i
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN filtered_store s ON ss.ss_store_sk = s.s_store_sk
JOIN filtered_promo p ON ss.ss_promo_sk = p.p_promo_sk
JOIN filtered_hd hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
JOIN filtered_reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
JOIN filtered_inventory inv ON inv.inv_item_sk = i.i_item_sk
GROUP BY
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    s.s_state,
    hd.hd_buy_potential,
    p.p_promo_name,
    r.r_reason_desc,
    wsit.web_name
ORDER BY total_store_sales DESC
LIMIT 100
