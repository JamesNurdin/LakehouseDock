WITH sold AS (
    SELECT
        s.s_store_name,
        d_sold.d_year,
        COUNT(*) AS order_cnt,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        MIN(ws.ws_ext_discount_amt) AS min_discount,
        MAX(ws.ws_ext_discount_amt) AS max_discount
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_quarter_seq = 7
      AND d_sold.d_first_dom = 2415506
      AND d_ship.d_weekend = 'N'
      AND ws.ws_net_paid_inc_ship > 5000
      AND s.s_manager = 'Joe Johnson'
      AND s.s_rec_start_date >= DATE '2000-01-01'
    GROUP BY s.s_store_name, d_sold.d_year
),
shipped AS (
    SELECT
        s.s_store_name,
        d_sold.d_year,
        COUNT(*) AS order_cnt,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        MIN(ws.ws_ext_discount_amt) AS min_discount,
        MAX(ws.ws_ext_discount_amt) AS max_discount
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_quarter_seq = 9
      AND d_sold.d_first_dom = 2415294
      AND d_ship.d_weekend = 'N'
      AND ws.ws_net_paid_inc_ship BETWEEN 3000 AND 4000
      AND s.s_manager = 'Robert Thompson'
      AND s.s_rec_start_date < DATE '2000-01-01'
    GROUP BY s.s_store_name, d_sold.d_year
)
SELECT *
FROM (
    SELECT * FROM sold
    UNION ALL
    SELECT * FROM shipped
) AS combined
ORDER BY total_sales DESC
LIMIT 100
