WITH sales_date AS (
    SELECT
        ws.ws_order_number,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_sold.d_date AS sold_date,
        d_ship.d_date AS ship_date
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_year = 2022
      AND d_sold.d_month_seq BETWEEN 1 AND 12
      AND ws.ws_quantity > 0
)
SELECT
    s.ws_order_number,
    s.sold_date,
    s.ship_date,
    w.w_warehouse_name,
    s.ws_net_profit,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY s.ws_net_profit DESC) AS profit_rank
FROM sales_date s
JOIN warehouse w
    ON s.ws_warehouse_sk = w.w_warehouse_sk
WHERE w.w_country = 'United States'
  AND EXISTS (
        SELECT 1
        FROM web_site wsit
        WHERE wsit.web_site_sk = s.ws_web_site_sk
          AND wsit.web_mkt_id IN (1, 2, 3)
      )
ORDER BY profit_rank ASC, s.ws_net_profit DESC
LIMIT 100
