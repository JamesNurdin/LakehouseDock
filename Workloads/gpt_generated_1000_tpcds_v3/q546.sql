WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_warehouse_sk,
        ws_sold_date_sk,
        ws_ship_date_sk,
        ws_sold_time_sk,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM web_sales
    GROUP BY ws_item_sk, ws_warehouse_sk, ws_sold_date_sk, ws_ship_date_sk, ws_sold_time_sk
)
SELECT
    ds.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    t.t_hour,
    w.w_warehouse_name,
    i.i_category,
    i.i_brand,
    ws_agg.total_sales,
    ws_agg.total_net_profit,
    SUM(ws_agg.total_net_profit) OVER (PARTITION BY w.w_warehouse_name ORDER BY ds.d_date ROWS UNBOUNDED PRECEDING) AS cum_profit_by_warehouse,
    cc.cc_name,
    cp_s.cp_catalog_number AS catalog_number_start,
    cp_e.cp_catalog_number AS catalog_number_end,
    cp_s.cp_type AS catalog_type_start,
    cp_e.cp_type AS catalog_type_end
FROM ws_agg
JOIN item i
    ON ws_agg.ws_item_sk = i.i_item_sk
JOIN warehouse w
    ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN date_dim ds
    ON ws_agg.ws_sold_date_sk = ds.d_date_sk
JOIN date_dim d_ship
    ON ws_agg.ws_ship_date_sk = d_ship.d_date_sk
JOIN time_dim t
    ON ws_agg.ws_sold_time_sk = t.t_time_sk
JOIN call_center cc
    ON cc.cc_open_date_sk = ds.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN catalog_page cp_s
    ON cp_s.cp_start_date_sk = ds.d_date_sk
JOIN catalog_page cp_e
    ON cp_e.cp_end_date_sk = ds.d_date_sk
WHERE ds.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
GROUP BY
    ds.d_date,
    d_ship.d_date,
    t.t_hour,
    w.w_warehouse_name,
    i.i_category,
    i.i_brand,
    ws_agg.total_sales,
    ws_agg.total_net_profit,
    cc.cc_name,
    cp_s.cp_catalog_number,
    cp_e.cp_catalog_number,
    cp_s.cp_type,
    cp_e.cp_type
ORDER BY ds.d_date DESC, ws_agg.total_sales DESC
LIMIT 100
