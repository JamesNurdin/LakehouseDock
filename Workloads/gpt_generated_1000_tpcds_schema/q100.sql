WITH
    intersect_orders AS (
        SELECT ws.ws_order_number
        FROM tpcds.web_sales ws
        JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
        WHERE p.p_discount_active = 'Y'
        INTERSECT
        SELECT ws2.ws_order_number
        FROM tpcds.web_sales ws2
        JOIN tpcds.time_dim t2 ON ws2.ws_sold_time_sk = t2.t_time_sk
        WHERE t2.t_sub_shift = 'morning'
    ),
    excluded_orders AS (
        SELECT ws_ex.ws_order_number
        FROM tpcds.web_sales ws_ex
        JOIN tpcds.customer_demographics cd_ex ON ws_ex.ws_bill_cdemo_sk = cd_ex.cd_demo_sk
        WHERE cd_ex.cd_dep_count = 0
    )
SELECT
    ws.ws_order_number,
    d_sold.d_date,
    t.t_hour,
    p.p_promo_name,
    s.s_store_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    ws.ws_net_profit,
    RANK() OVER (PARTITION BY s.s_store_name ORDER BY ws.ws_net_profit DESC) AS profit_rank,
    CASE WHEN ws.ws_quantity > 5 THEN 'Large' ELSE 'Small' END AS order_size_flag
FROM tpcds.web_sales ws
JOIN tpcds.date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN tpcds.store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.call_center cc ON cc.cc_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
  AND cd.cd_purchase_estimate >= 4000
  AND hd.hd_buy_potential = '5000-10000'
  AND p.p_channel_dmail = 'Y'
  AND s.s_market_manager = 'James Irvin'
  AND ws.ws_order_number NOT IN (SELECT ws_order_number FROM excluded_orders)
  AND ws.ws_order_number IN (SELECT ws_order_number FROM intersect_orders)
ORDER BY ws.ws_net_profit DESC
LIMIT 100
