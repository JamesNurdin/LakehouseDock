WITH page_mode_agg AS (
    SELECT
        ws.ws_web_page_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_net_paid) AS revenue,
        SUM(ws.ws_net_profit) AS profit,
        COUNT(*) AS sales_cnt,
        SUM(ws.ws_quantity) AS total_qty
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450300
      AND ws.ws_net_paid > 500
    GROUP BY ws.ws_web_page_sk, ws.ws_ship_mode_sk
),
type_ship_agg AS (
    SELECT
        wp.wp_type,
        pm.ws_ship_mode_sk,
        SUM(pm.revenue) AS type_ship_revenue,
        SUM(pm.profit) AS type_ship_profit,
        SUM(pm.sales_cnt) AS type_ship_sales,
        SUM(pm.total_qty) AS type_ship_qty
    FROM page_mode_agg pm
    JOIN web_page wp ON wp.wp_web_page_sk = pm.ws_web_page_sk
    WHERE wp.wp_type IN ('article', 'home', 'search')
    GROUP BY wp.wp_type, pm.ws_ship_mode_sk
    HAVING SUM(pm.revenue) > 100000
)
SELECT
    ts.wp_type,
    ts.ws_ship_mode_sk,
    ts.type_ship_revenue,
    ts.type_ship_profit,
    ts.type_ship_sales,
    ts.type_ship_qty,
    (ts.type_ship_profit / NULLIF(ts.type_ship_revenue, 0)) AS profit_margin,
    RANK() OVER (PARTITION BY ts.wp_type ORDER BY ts.type_ship_revenue DESC) AS ship_mode_rank
FROM type_ship_agg ts
ORDER BY ts.type_ship_revenue DESC
LIMIT 100
