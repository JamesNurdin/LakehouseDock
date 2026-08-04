-- Goal: Analyze total net paid and profit per call center and catalog return reason, combining catalog and web sales data, and compare order sets that appear in both sales channels and those with sales but no returns.
WITH intersect_orders AS (
    SELECT cs_order_number AS order_number FROM catalog_sales
    INTERSECT
    SELECT ws_order_number AS order_number FROM web_sales
),
except_orders AS (
    SELECT cs_order_number AS order_number FROM catalog_sales
    EXCEPT
    SELECT cr_order_number AS order_number FROM catalog_returns
)
SELECT
    cc.cc_name AS call_center_name,
    r_ret.r_reason_desc AS return_reason,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_indicator,
    (
        SELECT AVG(cs2.cs_ext_discount_amt)
        FROM catalog_sales cs2
        WHERE cs2.cs_quantity > 0
    ) AS avg_discount,
    (SELECT COUNT(DISTINCT order_number) FROM intersect_orders) AS intersect_order_count,
    (SELECT COUNT(DISTINCT order_number) FROM except_orders) AS sales_without_return_count
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp_sales ON cs.cs_catalog_page_sk = cp_sales.cp_catalog_page_sk
JOIN ship_mode sm_sales ON cs.cs_ship_mode_sk = sm_sales.sm_ship_mode_sk
JOIN promotion p_sales ON cs.cs_promo_sk = p_sales.p_promo_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN call_center cc2 ON cr.cr_call_center_sk = cc2.cc_call_center_sk
JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN reason r_ret ON cr.cr_reason_sk = r_ret.r_reason_sk
JOIN web_sales ws ON ws.ws_order_number = cs.cs_order_number
    AND ws.ws_item_sk = cs.cs_item_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN reason r_ws ON wr.wr_reason_sk = r_ws.r_reason_sk
WHERE cs.cs_quantity > 0
GROUP BY
    cc.cc_name,
    r_ret.r_reason_desc
ORDER BY total_net_paid DESC
LIMIT 100
