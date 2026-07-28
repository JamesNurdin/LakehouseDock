WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        ss.ss_cdemo_sk,
        ss.ss_promo_sk
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'Y'
),
filtered_web_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'Y'
)
SELECT
    i.i_item_id,
    i.i_category,
    w.w_city,
    COUNT(DISTINCT fs.ss_ticket_number) AS store_txn_cnt,
    SUM(fs.ss_ext_sales_price) AS store_sales_amt,
    SUM(fws.ws_ext_sales_price) AS web_sales_amt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    AVG(p.p_cost) AS avg_promo_cost
FROM filtered_sales fs
JOIN item i ON fs.ss_item_sk = i.i_item_sk
JOIN customer c ON fs.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON fs.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON fs.ss_cdemo_sk = cd.cd_demo_sk
JOIN promotion p ON fs.ss_promo_sk = p.p_promo_sk
JOIN filtered_web_sales fws ON fws.ws_item_sk = i.i_item_sk
JOIN warehouse w ON fws.ws_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_site we ON fws.ws_web_site_sk = we.web_site_sk
WHERE
    i.i_brand = 'BrandX'
    AND w.w_state = 'CA'
    AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_type = 'article'
    )
GROUP BY i.i_item_id, i.i_category, w.w_city
HAVING SUM(fs.ss_ext_sales_price) > 10000
ORDER BY store_sales_amt DESC
LIMIT 100
