WITH cr AS (
        SELECT
            cr_returned_date_sk,
            cr_return_amount,
            cr_return_quantity,
            cr_returned_time_sk,
            cr_call_center_sk,
            cr_catalog_page_sk,
            cr_reason_sk,
            cr_order_number
        FROM catalog_returns cr
    ),
    ws AS (
        SELECT
            ws_order_number,
            ws_quantity,
            ws_ext_sales_price,
            ws_sold_time_sk
        FROM web_sales ws
    )
SELECT
    cp.cp_type,
    td_return.t_hour AS return_hour,
    CASE WHEN r.r_reason_id = 'AAAAAAAANAAAAAAA' THEN 'Special' ELSE 'Other' END AS reason_category,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT ws.ws_order_number) AS num_sales_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    AVG(ws.ws_ext_sales_price - cr.cr_return_amount) AS avg_profit_diff
FROM cr
JOIN time_dim td_return ON cr.cr_returned_time_sk = td_return.t_time_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
-- additional aliases for deep‑join effect
JOIN time_dim td_return_dup ON cr.cr_returned_time_sk = td_return_dup.t_time_sk
JOIN call_center cc_dup ON cr.cr_call_center_sk = cc_dup.cc_call_center_sk
JOIN catalog_page cp_dup ON cr.cr_catalog_page_sk = cp_dup.cp_catalog_page_sk
JOIN reason r_dup ON cr.cr_reason_sk = r_dup.r_reason_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = td_return.t_time_sk
JOIN time_dim td_sold_dup ON ws.ws_sold_time_sk = td_sold_dup.t_time_sk
WHERE cr.cr_order_number NOT IN (
        SELECT ws2.ws_order_number
        FROM web_sales ws2
        WHERE ws2.ws_sold_time_sk = 12345
    )
GROUP BY
    cp.cp_type,
    td_return.t_hour,
    CASE WHEN r.r_reason_id = 'AAAAAAAANAAAAAAA' THEN 'Special' ELSE 'Other' END
ORDER BY total_return_amount DESC
LIMIT 100
