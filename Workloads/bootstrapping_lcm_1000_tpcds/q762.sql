SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_day_name,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    SUM(cs.cs_net_profit) - SUM(ws.ws_net_profit) AS profit_diff,
    AVG(cs.cs_quantity) AS avg_catalog_qty,
    AVG(ws.ws_quantity) AS avg_web_qty,
    s.s_state,
    s.s_market_desc,
    wp.wp_type,
    d_ship.d_month_seq AS catalog_ship_month,
    d_ws_ship.d_month_seq AS web_ship_month,
    d_wp_creation.d_year AS page_creation_year,
    d_wp_access.d_year AS page_access_year,
    ROW_NUMBER() OVER (PARTITION BY d_sold.d_year ORDER BY SUM(cs.cs_net_profit) - SUM(ws.ws_net_profit) DESC) AS profit_rank
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2020 AND 2022
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_day_name,
    s.s_state,
    s.s_market_desc,
    wp.wp_type,
    d_ship.d_month_seq,
    d_ws_ship.d_month_seq,
    d_wp_creation.d_year,
    d_wp_access.d_year
ORDER BY profit_rank
LIMIT 100
