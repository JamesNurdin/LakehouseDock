WITH sales_sample AS (
    SELECT
        ws_order_number,
        ws_sold_time_sk,
        ws_bill_cdemo_sk,
        ws_quantity,
        ws_net_profit,
        ws_ext_sales_price,
        ws_promo_sk
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    ws.ws_order_number,
    cc.cc_name,
    cp.cp_department,
    td.t_sub_shift,
    p.p_channel_email,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    COUNT(DISTINCT cr.cr_returned_date_sk) AS distinct_return_dates,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(ws.ws_net_profit) AS min_profit,
    MAX(ws.ws_net_profit) AS max_profit,
    lr.return_cnt
FROM sales_sample ws
JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = td.t_time_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS return_cnt
    FROM web_returns wr
    WHERE wr.wr_order_number = ws.ws_order_number
) lr ON TRUE
WHERE
    p.p_channel_email = 'N' AND
    p.p_start_date_sk IN (2450895, 2450347) AND
    cc.cc_state = 'CA' AND
    cp.cp_department = 'Electronics' AND
    td.t_sub_shift = 'evening' AND
    ws.ws_quantity > 5 AND
    ws.ws_net_profit > 0
GROUP BY
    ws.ws_order_number,
    cc.cc_name,
    cp.cp_department,
    td.t_sub_shift,
    p.p_channel_email,
    lr.return_cnt
ORDER BY total_sales DESC
LIMIT 100
