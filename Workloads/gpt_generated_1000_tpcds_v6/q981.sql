WITH cs_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
)
SELECT
    s.s_store_name,
    web.web_state,
    SUM(cs_base.cs_ext_sales_price)                               AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price)                                    AS total_web_sales,
    SUM(CASE WHEN p_active.p_discount_active = 'Y' THEN cs_base.cs_net_profit ELSE 0 END) AS profit_active_promo,
    COUNT(DISTINCT cs_base.cs_order_number)                      AS num_orders
FROM cs_base
JOIN time_dim td           ON cs_base.cs_sold_time_sk = td.t_time_sk
JOIN customer c_bill       ON cs_base.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN promotion p_active    ON cs_base.cs_promo_sk = p_active.p_promo_sk
JOIN web_sales ws          ON ws.ws_sold_time_sk = td.t_time_sk
JOIN promotion p_ws        ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN web_page wp           ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site web          ON ws.ws_web_site_sk = web.web_site_sk
JOIN store_returns sr     ON sr.sr_return_time_sk = td.t_time_sk
JOIN store s               ON sr.sr_store_sk = s.s_store_sk
JOIN customer c_ws        ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
JOIN customer c_sr        ON sr.sr_customer_sk = c_sr.c_customer_sk
GROUP BY s.s_store_name, web.web_state
HAVING SUM(cs_base.cs_ext_sales_price) > 10000
ORDER BY total_catalog_sales DESC
LIMIT 100
