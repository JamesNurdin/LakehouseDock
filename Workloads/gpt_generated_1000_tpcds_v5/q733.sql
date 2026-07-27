WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_profit AS cs_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        i.i_product_name,
        d_sold.d_date AS sold_date,
        t_sold.t_hour,
        sm.sm_code,
        wsite.web_country,
        wp.wp_url
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON cs.cs_order_number = ws.ws_order_number
        AND cs.cs_item_sk = ws.ws_item_sk
    JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d_sold.d_year = 2001
      AND t_sold.t_hour BETWEEN 9 AND 17
      AND sm.sm_code = 'AIR'
      AND i.i_manufact_id IN (260, 338)
      AND cs.cs_quantity > 1
      AND ws.ws_net_profit > 0
      AND wsite.web_country = 'United States'
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = ws.ws_item_sk
      )
)
SELECT
    i_product_name,
    sold_date,
    SUM(cs_net_profit + ws_net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count,
    ROW_NUMBER() OVER (PARTITION BY i_product_name ORDER BY SUM(cs_net_profit + ws_net_profit) DESC) AS rank_by_profit
FROM base
GROUP BY i_product_name, sold_date
HAVING SUM(cs_net_profit + ws_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
