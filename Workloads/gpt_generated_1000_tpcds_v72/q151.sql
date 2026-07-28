WITH cs_join AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        cc.cc_name,
        cp.cp_department,
        p.p_promo_name,
        sm.sm_type,
        w.w_warehouse_name,
        cd.cd_gender,
        hd.hd_buy_potential,
        cs.cs_ext_sales_price AS sales,
        cr.cr_return_amount AS return_amount,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_current_price > 50
      AND cc.cc_state = 'CA'
      AND inv.inv_quantity_on_hand >= 100
      AND cp.cp_department = 'Books'
),
ss_join AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        NULL AS cc_name,
        NULL AS cp_department,
        NULL AS p_promo_name,
        NULL AS sm_type,
        NULL AS w_warehouse_name,
        cd2.cd_gender,
        hd2.hd_buy_potential,
        ss.ss_ext_sales_price AS sales,
        sr.sr_return_amt AS return_amount,
        inv2.inv_quantity_on_hand
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd2 ON ss.ss_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN inventory inv2 ON inv2.inv_item_sk = i.i_item_sk
    WHERE i.i_current_price > 50
      AND ss.ss_quantity >= 2
),
ws_join AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        NULL AS cc_name,
        NULL AS cp_department,
        p.p_promo_name,
        sm.sm_type,
        w.w_warehouse_name,
        cd3.cd_gender,
        hd3.hd_buy_potential,
        ws.ws_ext_sales_price AS sales,
        cr2.cr_return_amount AS return_amount,
        inv3.inv_quantity_on_hand
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd3 ON ws.ws_bill_cdemo_sk = cd3.cd_demo_sk
    JOIN household_demographics hd3 ON ws.ws_bill_hdemo_sk = hd3.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN catalog_returns cr2 ON cr2.cr_item_sk = i.i_item_sk AND cr2.cr_order_number = ws.ws_order_number
    LEFT JOIN inventory inv3 ON inv3.inv_item_sk = i.i_item_sk AND inv3.inv_warehouse_sk = w.w_warehouse_sk
    WHERE we.web_tax_percentage > 0.03
      AND wp.wp_image_count >= 2
      AND i.i_current_price > 50
),
combined AS (
    SELECT * FROM cs_join
    UNION ALL
    SELECT * FROM ss_join
    UNION ALL
    SELECT * FROM ws_join
),
final_agg AS (
    SELECT
        i_item_sk,
        i_category,
        i_brand,
        cc_name,
        SUM(sales) AS total_sales,
        SUM(COALESCE(return_amount, 0)) AS total_returns,
        SUM(COALESCE(inv_quantity_on_hand, 0)) AS total_inventory
    FROM combined
    GROUP BY i_item_sk, i_category, i_brand, cc_name
    HAVING SUM(sales) > 10000
)
SELECT
    i_category,
    i_brand,
    cc_name,
    total_sales,
    total_returns,
    total_inventory
FROM final_agg fa
WHERE fa.i_item_sk NOT IN (SELECT cr_item_sk FROM catalog_returns)
ORDER BY total_sales DESC
LIMIT 100
