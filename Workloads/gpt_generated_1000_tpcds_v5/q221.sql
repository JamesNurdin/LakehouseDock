WITH sales_agg AS (
    SELECT
        we.web_name,
        sm.sm_ship_mode_id,
        wp.wp_url,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_page_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_qty,
        AVG(ws.ws_wholesale_cost) AS avg_wholesale_cost
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE wp.wp_rec_end_date BETWEEN DATE '1999-09-01' AND DATE '2001-09-30'
      AND ws.ws_wholesale_cost > 40
      AND ws.ws_quantity >= 2
      AND sm.sm_contract LIKE 'A%'
      AND we.web_state = 'CA'
      AND wp.wp_type = 'home'
    GROUP BY
        we.web_name,
        sm.sm_ship_mode_id,
        wp.wp_url,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_page_sk
)
SELECT
    web_name,
    sm_ship_mode_id,
    wp_url,
    total_profit,
    total_qty,
    avg_wholesale_cost,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY web_name ORDER BY total_qty DESC) AS qty_rank_within_site
FROM sales_agg
ORDER BY profit_rank
LIMIT 100
