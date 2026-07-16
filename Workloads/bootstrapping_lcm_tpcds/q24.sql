WITH store_dates AS (
    SELECT
        s.s_store_id,
        s.s_division_name,
        s.s_closed_date_sk,
        d.d_year AS store_closed_year,
        d.d_quarter_seq AS store_closed_quarter_seq,
        d.d_quarter_name AS store_closed_quarter_name
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
)
SELECT
    sd.s_division_name,
    w.w_warehouse_name,
    dd_sold.d_year AS sold_year,
    dd_sold.d_quarter_name AS sold_quarter,
    MIN(sd.store_closed_year) AS store_closed_year,
    MIN(dd_web_open.d_year) AS site_open_year,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    CASE
        WHEN SUM(ws.ws_net_profit) > 0 THEN 'POSITIVE'
        WHEN SUM(ws.ws_net_profit) = 0 THEN 'ZERO'
        ELSE 'NEGATIVE'
    END AS profit_category
FROM web_sales ws
JOIN date_dim dd_sold
    ON ws.ws_sold_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_ship
    ON ws.ws_ship_date_sk = dd_ship.d_date_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
JOIN date_dim dd_web_open
    ON site.web_open_date_sk = dd_web_open.d_date_sk
JOIN date_dim dd_web_close
    ON site.web_close_date_sk = dd_web_close.d_date_sk
JOIN store_dates sd
    ON sd.s_closed_date_sk = dd_ship.d_date_sk
WHERE dd_sold.d_year = 2022
  AND dd_ship.d_year = 2022
  AND dd_web_close.d_date >= dd_ship.d_date
GROUP BY ROLLUP (sd.s_division_name, w.w_warehouse_name, dd_sold.d_year, dd_sold.d_quarter_name)
HAVING SUM(ws.ws_net_paid) > 10000
ORDER BY total_profit DESC
LIMIT 100
