/*
Goal: Analyze sales performance by year, call center and shipping mode, combining catalog and web channels, while accounting for returns and promotions.
The query joins all 16 TPC‑DS tables using only the permitted join keys, applies several selective filters, aggregates key monetary measures, uses a CASE expression to isolate return amounts, orders by total net paid and limits the result to the top 100 rows.
*/
SELECT
    d.d_year,
    cc.cc_name,
    sm.sm_type,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    SUM(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_amount ELSE 0 END) AS total_return_amount,
    MAX(ws.ws_net_profit) AS max_web_profit
FROM
    catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                              AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                             AND wr.wr_item_sk = ws.ws_item_sk
                             AND wr.wr_reason_sk = r.r_reason_sk
WHERE
    d.d_year = 2001
    AND cc.cc_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND wsite.web_mkt_id = 3
    AND p.p_discount_active = 'Y'
GROUP BY
    d.d_year,
    cc.cc_name,
    sm.sm_type
ORDER BY
    total_net_paid DESC
LIMIT 100
