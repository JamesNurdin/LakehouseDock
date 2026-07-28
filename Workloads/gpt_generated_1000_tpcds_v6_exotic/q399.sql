SELECT
    d.d_year,
    cc.cc_state,
    i.i_brand,
    w.w_warehouse_name,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit)) AS total_profit
FROM
    date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
WHERE
    d.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND w.w_warehouse_sq_ft > 800000
    AND cc.cc_state = 'CA'
    AND cs.cs_quantity > 5
GROUP BY
    ROLLUP (d.d_year, cc.cc_state, i.i_brand, w.w_warehouse_name)
LIMIT 100
