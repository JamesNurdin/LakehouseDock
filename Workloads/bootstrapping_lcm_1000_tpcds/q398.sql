SELECT
    s.s_store_id,
    s.s_city,
    d_sold.d_year,
    wp.wp_type,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit)) / NULLIF(SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price), 0) * 100 AS overall_profit_margin_pct,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    CASE
        WHEN d_sold.d_quarter_seq % 2 = 0 THEN 'EvenQuarter'
        ELSE 'OddQuarter'
    END AS quarter_parity
FROM catalog_sales cs
INNER JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
INNER JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
INNER JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
INNER JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
INNER JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
INNER JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
INNER JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
INNER JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND wp.wp_type = 'product'
GROUP BY
    s.s_store_id,
    s.s_city,
    d_sold.d_year,
    wp.wp_type,
    d_sold.d_quarter_seq
HAVING SUM(cs.cs_ext_sales_price) > 5000
ORDER BY catalog_sales_amount DESC
LIMIT 50
