SELECT
    s.s_store_id,
    s.s_store_name,
    d_store.d_year AS store_closed_year,
    d_store.d_current_month AS store_closed_month,
    d_cs_sold.d_year AS catalog_sold_year,
    d_cs_ship.d_year AS catalog_ship_year,
    d_cr_return.d_year AS return_year,
    d_ws_sold.d_year AS web_sold_year,
    d_ws_ship.d_year AS web_ship_year,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    COUNT(DISTINCT cr.cr_order_number) AS return_order_cnt
FROM
    store s
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_store.d_date_sk
    JOIN date_dim d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN date_dim d_cs_ship ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_cr_return ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d_store.d_date_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
WHERE
    d_store.d_year = 2001
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_store.d_year,
    d_store.d_current_month,
    d_cs_sold.d_year,
    d_cs_ship.d_year,
    d_cr_return.d_year,
    d_ws_sold.d_year,
    d_ws_ship.d_year
