WITH sold_dates AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_day_name
    FROM tpcds.date_dim d
    WHERE d.d_year = 2002
),
ship_dates AS (
    SELECT
        d.d_date_sk,
        d.d_date AS ship_date,
        d.d_month_seq AS ship_month_seq
    FROM tpcds.date_dim d
    WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
)
SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    sd.d_date AS sold_date,
    shd.ship_date,
    ws.ws_quantity,
    ws.ws_list_price,
    ws.ws_wholesale_cost,
    ws.ws_net_profit,
    CASE
        WHEN ws.ws_net_profit / NULLIF(ws.ws_ext_sales_price, 0) > 0.30 THEN 'HIGH'
        WHEN ws.ws_net_profit / NULLIF(ws.ws_ext_sales_price, 0) > 0.10 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_margin_category,
    ROW_NUMBER() OVER (
        PARTITION BY sd.d_month_seq
        ORDER BY ws.ws_net_profit DESC
    ) AS month_profit_rank
FROM tpcds.web_sales ws
JOIN sold_dates sd
    ON ws.ws_sold_date_sk = sd.d_date_sk
JOIN ship_dates shd
    ON ws.ws_ship_date_sk = shd.d_date_sk
WHERE ws.ws_list_price BETWEEN 20 AND 200
  AND ws.ws_wholesale_cost < 50
  AND ws.ws_quantity >= 2
  AND ws.ws_ext_discount_amt < 10
  AND shd.ship_date >= DATE '2002-06-01'
ORDER BY sd.d_month_seq, month_profit_rank
LIMIT 100
