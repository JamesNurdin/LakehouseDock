WITH filtered_items AS (
        SELECT i_item_sk
        FROM item
        WHERE i_current_price > 50
        INTERSECT
        SELECT inv_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 0
    )
SELECT
    store.s_state,
    item.i_category,
    income_band.ib_income_band_sk,
    web_site.web_mkt_id,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    CASE
        WHEN SUM(ss.ss_net_paid) > SUM(ws.ws_net_paid) THEN 'Store > Web'
        ELSE 'Web >= Store'
    END AS sales_comparison,
    (SELECT AVG(p_cost) FROM promotion WHERE p_discount_active = 'Y') AS avg_active_promo_cost
FROM
    store_sales ss
    JOIN item ON ss.ss_item_sk = item.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ON hd.hd_income_band_sk = income_band.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store ON ss.ss_store_sk = store.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = store.s_store_sk
    JOIN inventory inv ON inv.inv_item_sk = item.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = item.i_item_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = item.i_item_sk
WHERE
    store.s_zip = '49003'
    AND store.s_gmt_offset = -5.00
    AND income_band.ib_lower_bound >= 50000
    AND web_site.web_mkt_id IN (1, 2)
    AND item.i_item_sk IN (SELECT i_item_sk FROM filtered_items)
GROUP BY CUBE (store.s_state, item.i_category, income_band.ib_income_band_sk, web_site.web_mkt_id)
ORDER BY total_store_sales DESC
LIMIT 100
