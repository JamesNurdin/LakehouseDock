/*
Goal: Compare the monthly net‑profit performance of AIR vs SEA shipping modes for two consecutive years, rank carriers within each month by profit, and show the top 5 carriers per month.
*/
WITH filtered_ship_modes AS (
    SELECT DISTINCT
        sm_ship_mode_sk,
        sm_carrier,
        sm_code,
        sm_type
    FROM ship_mode
    WHERE sm_carrier IN ('RUPEKSA', 'BARIAN')
),
air_sales AS (
    SELECT
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month,
        d_ship.d_month_seq AS ship_month,
        fsm.sm_carrier,
        fsm.sm_code,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN filtered_ship_modes fsm ON ws.ws_ship_mode_sk = fsm.sm_ship_mode_sk
    WHERE fsm.sm_type = 'AIR'
      AND d_sold.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND ws.ws_quantity > 1
    GROUP BY d_sold.d_year,
             d_sold.d_month_seq,
             d_ship.d_month_seq,
             fsm.sm_carrier,
             fsm.sm_code
    HAVING SUM(ws.ws_net_profit) > 1000
),
sea_sales AS (
    SELECT
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month,
        d_ship.d_month_seq AS ship_month,
        fsm.sm_carrier,
        fsm.sm_code,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN filtered_ship_modes fsm ON ws.ws_ship_mode_sk = fsm.sm_ship_mode_sk
    WHERE fsm.sm_type = 'SEA'
      AND d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND ws.ws_quantity > 1
    GROUP BY d_sold.d_year,
             d_sold.d_month_seq,
             d_ship.d_month_seq,
             fsm.sm_carrier,
             fsm.sm_code
    HAVING SUM(ws.ws_net_profit) > 1000
),
combined_sales AS (
    SELECT * FROM air_sales
    UNION ALL
    SELECT * FROM sea_sales
),
ranked_sales AS (
    SELECT
        sold_year,
        sold_month,
        ship_month,
        sm_carrier,
        sm_code,
        total_net_profit,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY sold_year, sold_month ORDER BY total_net_profit DESC) AS profit_rank
    FROM combined_sales
)
SELECT
    sold_year,
    sold_month,
    ship_month,
    sm_carrier,
    sm_code,
    total_net_profit,
    total_quantity,
    profit_rank
FROM ranked_sales
WHERE profit_rank <= 5
ORDER BY sold_year, sold_month, profit_rank
