WITH sales_enhanced AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_list_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_net_paid,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_ship.d_month_seq AS ship_month_seq,
        d_sold.d_quarter_name,
        CASE WHEN ws.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_year BETWEEN 1999 AND 2002
      AND d_sold.d_current_quarter = 'Y'
      AND ws.ws_quantity >= 2
      AND ws.ws_list_price BETWEEN 20 AND 100
)
SELECT
    ws_enh.ws_sold_date_sk,
    ws_enh.ws_ship_date_sk,
    ws_enh.ws_order_number,
    ws_enh.ws_quantity,
    ws_enh.ws_list_price,
    ws_enh.ws_ext_sales_price,
    ws_enh.ws_net_profit,
    ws_enh.ws_net_paid,
    ws_enh.d_year,
    ws_enh.d_month_seq,
    ws_enh.ship_month_seq,
    ws_enh.d_quarter_name,
    ws_enh.profit_flag,
    RANK() OVER (PARTITION BY ws_enh.d_year ORDER BY ws_enh.ws_net_profit DESC) AS profit_rank_year,
    SUM(ws_enh.ws_ext_sales_price) OVER (
        PARTITION BY ws_enh.d_year
        ORDER BY ws_enh.ws_sold_date_sk
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7day_sales
FROM sales_enhanced ws_enh
ORDER BY ws_enh.d_year DESC, profit_rank_year ASC
LIMIT 100
