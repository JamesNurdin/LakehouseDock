WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_state,
        p_ws.p_promo_id,
        sm.sm_ship_mode_id,
        w.w_warehouse_id,
        site.web_site_id,
        COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0) AS total_sales,
        COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(wr.wr_return_amt, 0) AS total_profit,
        COALESCE(wr.wr_return_amt, 0) AS total_return_amt
    FROM date_dim d
    INNER JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    INNER JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
    INNER JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    INNER JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    INNER JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    INNER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                           AND wr.wr_item_sk = ws.ws_item_sk
    WHERE d.d_year = 2000
      AND s.s_state = 'CA'
      AND p_ws.p_discount_active = 'Y'
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        s_store_id AS store_id,
        s_state AS state,
        p_promo_id AS promo_id,
        sm_ship_mode_id AS ship_mode_id,
        w_warehouse_id AS warehouse_id,
        web_site_id,
        SUM(total_sales) AS sum_sales,
        SUM(total_profit) AS sum_profit,
        SUM(total_return_amt) AS sum_return
    FROM base
    GROUP BY CUBE (d_year, d_month_seq, s_store_id, s_state, p_promo_id, sm_ship_mode_id, w_warehouse_id, web_site_id)
)
SELECT
    d_year,
    d_month_seq,
    store_id,
    state,
    promo_id,
    ship_mode_id,
    warehouse_id,
    web_site_id,
    sum_sales,
    sum_profit,
    sum_return,
    SUM(sum_sales) OVER (PARTITION BY d_year) AS year_sales_total,
    RANK() OVER (ORDER BY sum_sales DESC) AS sales_rank,
    (SELECT COUNT(*) FROM promotion p_sub WHERE p_sub.p_discount_active = 'Y') AS total_active_promotions
FROM agg
ORDER BY sum_sales DESC
LIMIT 100
