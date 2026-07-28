WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        i.i_current_price,
        i.i_brand,
        w.w_state,
        cc.cc_company,
        cc.cc_name AS call_center_name,
        hd.hd_dep_count,
        ib.ib_upper_bound,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        site.web_name,
        CASE WHEN cr.cr_return_quantity IS NULL THEN 0 ELSE 1 END AS has_return
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr ON ws.ws_item_sk = cr.cr_item_sk
                                 AND ws.ws_warehouse_sk = cr.cr_warehouse_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
                             AND w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND i.i_current_price > 20
      AND w.w_state = 'CA'
      AND cc.cc_company = 3
      AND hd.hd_dep_count >= 2
      AND ib.ib_upper_bound <= 80000
      AND (inv.inv_quantity_on_hand > 0 OR inv.inv_quantity_on_hand IS NULL)
)
SELECT
    web_name,
    call_center_name,
    COUNT(*) AS orders,
    SUM(ws_quantity) AS total_quantity,
    AVG(ws_net_paid) AS avg_net_paid,
    SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount
FROM sales_agg
GROUP BY web_name, call_center_name
HAVING AVG(ws_net_paid) > (
    SELECT AVG(ws_net_paid) FROM sales_agg
)
ORDER BY total_return_amount DESC
LIMIT 100
