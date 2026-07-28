WITH recent_dates AS (
    SELECT d_date_sk, d_year, d_month_seq
    FROM date_dim
    WHERE d_year = 2001
)
SELECT
    s.s_store_name,
    cp.cp_description,
    rd.d_year,
    SUM(ss.ss_net_profit) AS store_sales_profit,
    SUM(cs.cs_net_profit) AS catalog_sales_profit,
    SUM(CASE WHEN cr.cr_return_amount IS NOT NULL THEN cr.cr_return_amount ELSE 0 END) AS total_catalog_return,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_orders,
    CASE
        WHEN SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_return_amount), 0) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS overall_status
FROM recent_dates rd
JOIN store_sales ss
    ON ss.ss_sold_date_sk = rd.d_date_sk
JOIN store s
    ON s.s_store_sk = ss.ss_store_sk
JOIN item i
    ON i.i_item_sk = ss.ss_item_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = rd.d_date_sk
    AND cs.cs_item_sk = i.i_item_sk
JOIN catalog_page cp
    ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
JOIN call_center cc
    ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returned_date_sk = rd.d_date_sk
LEFT JOIN call_center cc2
    ON cc2.cc_call_center_sk = cr.cr_call_center_sk
LEFT JOIN (
    SELECT inv_item_sk, inv_date_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 800
) inv
    ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_date_sk = rd.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_date_sk = rd.d_date_sk
WHERE EXISTS (
    SELECT 1 FROM ship_mode sm2
    WHERE sm2.sm_carrier = sm.sm_carrier
      AND sm2.sm_code = sm.sm_code
      AND sm2.sm_ship_mode_id <> sm.sm_ship_mode_id
)
GROUP BY
    s.s_store_name,
    cp.cp_description,
    rd.d_year
ORDER BY
    overall_status DESC,
    store_sales_profit DESC
LIMIT 100
