WITH sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
        COUNT(*) AS order_cnt,
        AVG(ws.ws_net_paid_inc_ship_tax) AS avg_sales
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    WHERE p.p_channel_event = 'N'
      AND w.w_zip = '35709'
      AND ws.ws_net_paid_inc_ship_tax > 1000
      AND t.t_hour BETWEEN 9 AND 17
      AND wp.wp_type = 'content'
      AND s.web_state = 'CA'
      AND ws.ws_quantity > 1
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_city, w.w_state
)
SELECT
    sa.w_warehouse_name AS warehouse_name,
    sa.w_city AS city,
    sa.w_state AS state,
    sa.total_sales,
    sa.order_cnt,
    sa.avg_sales,
    RANK() OVER (PARTITION BY sa.w_state ORDER BY sa.total_sales DESC) AS state_sales_rank,
    (SELECT MAX(total_sales) FROM sales_agg sa2 WHERE sa2.w_state = sa.w_state) AS max_state_sales,
    (SELECT AVG(total_sales) FROM sales_agg) AS overall_avg_state_sales
FROM sales_agg sa
ORDER BY sa.w_state, state_sales_rank
