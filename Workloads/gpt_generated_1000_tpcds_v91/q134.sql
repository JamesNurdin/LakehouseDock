/* Goal: Compute aggregated net profit, discount, and return amounts by item brand, category, shipping mode, call center division, and return reason, combining web sales, catalog returns, and related dimension tables. */
WITH sales_items AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_ship_mode_sk,
        i.i_brand_id,
        i.i_category,
        i.i_formulation
    FROM web_sales ws
    INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
)
SELECT
    si.i_brand_id,
    si.i_category,
    sm.sm_type,
    cc.cc_division,
    r.r_reason_desc,
    COUNT(DISTINCT si.ws_order_number) AS distinct_orders,
    SUM(si.ws_net_profit) AS total_net_profit,
    AVG(si.ws_ext_discount_amt) AS avg_discount,
    SUM(wr_agg.total_web_return_amt) AS total_web_return_amount,
    SUM(cr_agg.total_catalog_return_amt) AS total_catalog_return_amount
FROM sales_items si
INNER JOIN ship_mode sm ON si.ws_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN web_returns wr ON wr.wr_item_sk = si.ws_item_sk AND wr.wr_order_number = si.ws_order_number
INNER JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
INNER JOIN catalog_returns cr ON cr.cr_item_sk = si.ws_item_sk
INNER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
INNER JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN LATERAL (
    SELECT SUM(wr2.wr_return_amt) AS total_web_return_amt
    FROM web_returns wr2
    WHERE wr2.wr_order_number = si.ws_order_number
) wr_agg ON TRUE
LEFT JOIN LATERAL (
    SELECT SUM(cr2.cr_return_amount) AS total_catalog_return_amt
    FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = si.ws_item_sk
) cr_agg ON TRUE
WHERE
    si.i_brand_id = 2002002
    AND cc.cc_division = 4
    AND si.i_formulation LIKE '%steel%'
    AND si.ws_sold_date_sk BETWEEN 2451545 AND 2451910
    AND r.r_reason_desc IN (
        SELECT r_sub.r_reason_desc
        FROM reason r_sub
        WHERE r_sub.r_reason_id LIKE 'R%'
    )
GROUP BY
    si.i_brand_id,
    si.i_category,
    sm.sm_type,
    cc.cc_division,
    r.r_reason_desc
ORDER BY total_net_profit DESC
LIMIT 100
