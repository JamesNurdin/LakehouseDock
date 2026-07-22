WITH item_aggregates AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS catalog_sales_total,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS store_sales_total,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS web_sales_total,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS catalog_return_total,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS store_return_total,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
        MAX(inv.inv_quantity_on_hand) AS max_quantity_on_hand,
        MIN(p.p_promo_name) AS promo_name,
        MIN(wh.w_warehouse_name) AS warehouse_name,
        MIN(st.s_store_name) AS store_name,
        MIN(ws_site.web_name) AS web_site_name,
        MIN(cp.cp_department) AS catalog_department,
        MIN(hd.hd_income_band_sk) AS income_band_sk,
        MIN(c.c_customer_id) AS sample_customer_id
    FROM
        item i
        LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
        LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_order_number = cs.cs_order_number
        LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN store st ON st.s_store_sk = ss.ss_store_sk
        LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
        LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        LEFT JOIN web_site ws_site ON ws_site.web_site_sk = ws.ws_web_site_sk
        LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
        LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        LEFT JOIN warehouse wh ON wh.w_warehouse_sk = inv.inv_warehouse_sk
        LEFT JOIN customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
        LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
    WHERE
        i.i_current_price > 30.00
        AND i.i_brand_id IN (1, 2, 3)
        AND i.i_color = 'Red'
        AND inv.inv_quantity_on_hand > 0
        AND wh.w_state = 'CA'
        AND st.s_store_sk = 25
        AND ws_site.web_site_id = 'AAAAAAAADBAAAAAA'
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price
)
SELECT
    ia.i_item_id,
    ia.i_product_name,
    ia.i_current_price,
    ia.catalog_sales_total,
    ia.store_sales_total,
    ia.web_sales_total,
    ia.catalog_return_total,
    ia.store_return_total,
    (ia.catalog_sales_total - ia.catalog_return_total) AS net_catalog_sales,
    (ia.store_sales_total - ia.store_return_total) AS net_store_sales,
    ia.max_quantity_on_hand,
    ia.promo_name,
    ia.warehouse_name,
    ia.store_name,
    ia.web_site_name,
    ia.catalog_department,
    ia.income_band_sk,
    ia.sample_customer_id,
    (SELECT COUNT(*) FROM catalog_returns cr2 WHERE cr2.cr_item_sk = ia.i_item_sk AND cr2.cr_return_amount > 100) AS high_value_return_cnt
FROM
    item_aggregates ia
WHERE
    ia.catalog_sales_total > 1000
    AND ia.store_sales_total > 500
    AND ia.web_sales_total > 200
ORDER BY
    net_catalog_sales DESC,
    net_store_sales DESC
LIMIT 100
