WITH
    ss AS (
        SELECT ss.ss_sold_date_sk,
               ss.ss_sold_time_sk,
               ss.ss_customer_sk,
               ss.ss_addr_sk,
               ss.ss_store_sk,
               ss.ss_promo_sk,
               ss.ss_net_profit
        FROM store_sales ss
    ),
    cs AS (
        SELECT cs.cs_sold_date_sk,
               cs.cs_bill_customer_sk,
               cs.cs_bill_addr_sk,
               cs.cs_order_number,
               cs.cs_promo_sk,
               cs.cs_call_center_sk,
               cs.cs_warehouse_sk,
               cs.cs_net_profit
        FROM catalog_sales cs
    ),
    cr AS (
        SELECT cr.cr_returned_date_sk,
               cr.cr_order_number,
               cr.cr_net_loss
        FROM catalog_returns cr
    ),
    ws AS (
        SELECT ws.ws_sold_date_sk,
               ws.ws_bill_customer_sk,
               ws.ws_bill_addr_sk,
               ws.ws_web_page_sk,
               ws.ws_web_site_sk,
               ws.ws_warehouse_sk,
               ws.ws_net_profit
        FROM web_sales ws
    )
SELECT
    d_sold.d_year AS year,
    s.s_store_name,
    p.p_promo_name,
    SUM(ss.ss_net_profit) AS store_sales_profit,
    SUM(cs.cs_net_profit) AS catalog_sales_profit,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    SUM(cr.cr_net_loss) AS catalog_returns_loss
FROM
    ss
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN promotion p2 ON cs.cs_promo_sk = p2.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w1 ON cs.cs_warehouse_sk = w1.w_warehouse_sk
    JOIN cr ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE
    d_sold.d_year = 2002
    AND ca.ca_state = 'CA'
GROUP BY
    d_sold.d_year,
    s.s_store_name,
    p.p_promo_name
ORDER BY
    d_sold.d_year,
    s.s_store_name,
    p.p_promo_name
