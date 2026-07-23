WITH sales_agg AS (
    SELECT
        wsite.web_name AS site_name,
        p.p_promo_name AS promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE p.p_channel_dmail = 'Y'
      AND sm.sm_type = 'AIR'
      AND wp.wp_autogen_flag = 'N'
      AND ws.ws_wholesale_cost > 50
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY wsite.web_name, p.p_promo_name
    HAVING SUM(ws.ws_net_profit) > (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) * 1.5
)
SELECT
    site_name,
    promo_name,
    order_cnt,
    total_net_profit,
    total_sales,
    total_return_amount,
    avg_discount,
    (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS global_avg_net_profit,
    total_net_profit / (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS profit_to_global_ratio
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
