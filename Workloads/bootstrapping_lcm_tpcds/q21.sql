WITH aggregated_sales AS (
    SELECT
        d_sold.d_year AS year,
        d_sold.d_quarter_seq AS quarter_seq,
        store.s_store_id AS store_id,
        store.s_city AS store_city,
        w.w_warehouse_name AS warehouse_name,
        w.w_city AS warehouse_city,
        site.web_name AS web_name,
        site.web_city AS site_city,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS profit_margin
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    LEFT JOIN date_dim d_open ON site.web_open_date_sk = d_open.d_date_sk
    LEFT JOIN date_dim d_close ON site.web_close_date_sk = d_close.d_date_sk
    JOIN store ON store.s_closed_date_sk = d_sold.d_date_sk
    GROUP BY
        d_sold.d_year,
        d_sold.d_quarter_seq,
        store.s_store_id,
        store.s_city,
        w.w_warehouse_name,
        w.w_city,
        site.web_name,
        site.web_city
    HAVING SUM(ws.ws_ext_sales_price) > 50000
)
SELECT
    year,
    quarter_seq,
    store_id,
    store_city,
    warehouse_name,
    warehouse_city,
    web_name,
    site_city,
    order_cnt,
    total_quantity,
    total_sales,
    total_net_profit,
    avg_discount,
    profit_margin,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated_sales
ORDER BY profit_rank
LIMIT 10
