WITH ws_summary AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_promo_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_promo_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk
)

SELECT
    d.d_date,
    p.p_promo_name,
    sm.sm_type,
    w.w_warehouse_name,
    wp.wp_url,
    ws_summary.total_net_profit,
    ws_summary.distinct_orders,
    CASE
        WHEN ws_summary.avg_net_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_category,
    ws_summary.total_sales
FROM ws_summary
JOIN date_dim d ON ws_summary.ws_sold_date_sk = d.d_date_sk
JOIN promotion p ON ws_summary.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON ws_summary.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws_summary.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws_summary.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws_summary.ws_web_site_sk = we.web_site_sk
JOIN customer c_bill ON ws_summary.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON ws_summary.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN time_dim t ON ws_summary.ws_sold_time_sk = t.t_time_sk
WHERE
    d.d_year = 2000
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND w.w_state = 'CA'
    AND c_bill.c_birth_country = 'IRELAND'
    AND t.t_hour BETWEEN 9 AND 17
    AND we.web_name LIKE '%Site%'
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN customer c_ret ON cr.cr_refunded_customer_sk = c_ret.c_customer_sk
        JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
        WHERE d_cr.d_date_sk = ws_summary.ws_sold_date_sk
          AND c_ret.c_customer_sk = ws_summary.ws_bill_customer_sk
          AND cc.cc_manager = 'John Doe'
          AND cr.cr_return_amount > 100
    )
    AND EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN customer c_wr ON wr.wr_refunded_customer_sk = c_wr.c_customer_sk
        JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        WHERE d_wr.d_date_sk = ws_summary.ws_sold_date_sk
          AND c_wr.c_customer_sk = ws_summary.ws_bill_customer_sk
          AND r.r_reason_desc LIKE '%defect%'
    )
    AND EXISTS (
        SELECT 1
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
        JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
        WHERE d_ss.d_date_sk = ws_summary.ws_sold_date_sk
          AND c_ss.c_customer_sk = ws_summary.ws_bill_customer_sk
          AND s.s_state = 'CA'
          AND ss.ss_quantity > 5
    )
ORDER BY d.d_date, p.p_promo_name
