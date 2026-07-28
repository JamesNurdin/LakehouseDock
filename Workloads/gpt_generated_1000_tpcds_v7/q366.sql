WITH sales_returns AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_sold_date_sk,
        d_sold.d_year,
        d_sold.d_month_seq,
        sm.sm_ship_mode_id,
        sm.sm_type,
        wsite.web_site_id,
        wsite.web_class,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn_site_profit
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN web_returns wr
        ON ws.ws_item_sk = wr.wr_item_sk
       AND ws.ws_order_number = wr.wr_order_number
    WHERE d_sold.d_year = 2001                              -- filter 1
      AND d_sold.d_month_seq BETWEEN 1200 AND 1220        -- filter 2
      AND sm.sm_type = 'AIR'                               -- filter 3
      AND t_sold.t_hour BETWEEN 9 AND 17                  -- filter 4
      AND wsite.web_class = 'Unknown'                     -- filter 5
      AND (wr.wr_return_quantity IS NULL OR wr.wr_return_quantity > 0)  -- filter 6
      AND ws.ws_quantity >= 1                              -- filter 7
)
SELECT
    web_site_id,
    sm_ship_mode_id,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    COUNT(*) AS order_count,
    DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM sales_returns
GROUP BY web_site_id, sm_ship_mode_id
HAVING SUM(ws_ext_sales_price) > 10000
ORDER BY profit_rank
LIMIT 20
