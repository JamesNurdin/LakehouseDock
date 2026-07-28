WITH joined_data AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ws.ws_net_paid,
        cc.cc_state,
        w.w_city,
        i.i_category
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Books'
      AND cc.cc_state = 'CA'
      AND w.w_city = 'Lakeview'
      AND ws.ws_net_paid > 1000
),
sales_summary AS (
    SELECT
        p_promo_id,
        d_year,
        SUM(ss_ext_sales_price) AS promo_sales,
        SUM(ss_net_profit) AS promo_profit
    FROM joined_data
    GROUP BY p_promo_id, d_year
)
SELECT
    d_year,
    AVG(promo_sales) AS avg_sales_per_promo,
    AVG(promo_profit) AS avg_profit_per_promo
FROM sales_summary
GROUP BY d_year
HAVING AVG(promo_sales) > 5000
ORDER BY d_year
LIMIT 100
