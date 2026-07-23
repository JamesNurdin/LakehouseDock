WITH
    ss_base AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_sold_time_sk,
            ss.ss_hdemo_sk,
            ss.ss_store_sk,
            ss.ss_promo_sk,
            ss.ss_ext_sales_price,
            ss.ss_net_profit,
            ss.ss_quantity
        FROM store_sales ss
    )
SELECT
    s.s_store_name,
    s.s_state,
    sm.sm_carrier,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    ss_date.d_year AS sales_year,
    SUM(ss.ss_ext_sales_price) AS total_store_sales_ext,
    SUM(ws.ws_ext_sales_price) AS total_web_sales_ext,
    SUM(ss.ss_net_profit + ws.ws_net_profit) AS total_net_profit,
    SUM(CASE WHEN sm.sm_carrier = 'FEDEX' THEN ws.ws_ext_sales_price ELSE 0 END) AS fedex_web_sales
FROM store_sales ss
JOIN date_dim ss_date
    ON ss.ss_sold_date_sk = ss_date.d_date_sk
JOIN time_dim ss_time
    ON ss.ss_sold_time_sk = ss_time.t_time_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim promo_start
    ON p.p_start_date_sk = promo_start.d_date_sk
JOIN date_dim promo_end
    ON p.p_end_date_sk = promo_end.d_date_sk
JOIN web_sales ws
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim ws_sold_date
    ON ws.ws_sold_date_sk = ws_sold_date.d_date_sk
JOIN date_dim ws_ship_date
    ON ws.ws_ship_date_sk = ws_ship_date.d_date_sk
JOIN time_dim ws_time
    ON ws.ws_sold_time_sk = ws_time.t_time_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
GROUP BY
    s.s_store_name,
    s.s_state,
    sm.sm_carrier,
    p.p_discount_active,
    ss_date.d_year
ORDER BY
    total_net_profit DESC
LIMIT 100
