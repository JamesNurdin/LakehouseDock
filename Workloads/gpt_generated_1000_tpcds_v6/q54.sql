WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_web_page_sk,
        ws.ws_ship_mode_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_ext_discount_amt,
        ws.ws_ext_tax,
        ws.ws_net_paid
    FROM web_sales ws
    WHERE ws.ws_ext_sales_price > 100
      AND ws.ws_quantity >= 1
)
SELECT
    s.ws_order_number,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    i.i_product_name,
    COALESCE(sm.sm_code, 'UNKNOWN') AS ship_mode_code,
    wp.wp_type,
    CASE
        WHEN s.ws_net_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_flag,
    s.ws_ext_sales_price,
    (
        SELECT AVG(ws2.ws_net_profit)
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = d_sold.d_year
    ) AS avg_yearly_profit,
    RANK() OVER (PARTITION BY d_sold.d_year ORDER BY s.ws_net_profit DESC) AS profit_rank,
    cp.cp_department
FROM sales s
JOIN date_dim d_sold
    ON s.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON s.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i
    ON s.ws_item_sk = i.i_item_sk
LEFT JOIN ship_mode sm
    ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
    ON s.ws_web_page_sk = wp.wp_web_page_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN date_dim d_catalog
    ON cp.cp_end_date_sk = d_catalog.d_date_sk
WHERE d_sold.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND sm.sm_code IN ('AIR', 'SEA')
  AND wp.wp_type = 'content'
  AND cp.cp_department = 'Books'
ORDER BY profit_rank
LIMIT 100
