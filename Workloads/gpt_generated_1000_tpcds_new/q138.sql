WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    cc.cc_state,
    s.s_state,
    ws_site.web_name,
    ib.ib_income_band_sk,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(sr.sr_net_loss) AS total_store_returns_loss,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(inv_agg.total_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(i.i_current_price) AS min_item_price,
    MAX(i.i_current_price) AS max_item_price,
    ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_net_paid) DESC) AS sales_rank
FROM catalog_sales cs
    INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    INNER JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    FULL OUTER JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason reason_cr ON cr.cr_reason_sk = reason_cr.r_reason_sk
    LEFT JOIN call_center cc_cr ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
    LEFT JOIN catalog_page cp_cr ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
    LEFT JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    LEFT JOIN item i_cr ON cr.cr_item_sk = i_cr.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason reason_sr ON sr.sr_reason_sk = reason_sr.r_reason_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    cc.cc_state = 'CA'
    AND s.s_state = 'TX'
    AND i.i_brand = 'Brand#12'
    AND ib.ib_lower_bound >= 100000
    AND ws_site.web_name = 'Site#1'
GROUP BY
    cc.cc_state,
    s.s_state,
    ws_site.web_name,
    ib.ib_income_band_sk
ORDER BY total_catalog_sales DESC
