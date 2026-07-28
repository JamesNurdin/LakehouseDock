WITH filtered_sales AS (
    SELECT
        sw.ws_order_number,
        sw.ws_sold_time_sk,
        sw.ws_ext_sales_price,
        sw.ws_ext_tax,
        sw.ws_coupon_amt,
        sw.ws_quantity,
        sw.ws_net_profit,
        sw.ws_web_page_sk,
        sw.ws_item_sk,
        t.t_hour,
        t.t_minute,
        wp.wp_type,
        wp.wp_autogen_flag,
        wp.wp_web_page_id
    FROM web_sales sw
    JOIN time_dim t
      ON sw.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp
      ON sw.ws_web_page_sk = wp.wp_web_page_sk
    WHERE t.t_hour BETWEEN 9 AND 17                                 -- filter 1
      AND t.t_minute IN (5, 11, 18)                                 -- filter 2
      AND wp.wp_autogen_flag = 'Y'                                   -- filter 3
      AND wp.wp_type = 'Home'                                         -- filter 4
      AND wp.wp_web_page_id = 'AAAAAAAAACAAAAAA'                      -- filter 5
      AND sw.ws_ext_tax > 20                                          -- filter 6
      AND sw.ws_coupon_amt < 3000                                     -- filter 7
      AND sw.ws_quantity >= 1                                         -- filter 8
      AND EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_order_number = sw.ws_order_number
              AND wr.wr_item_sk = sw.ws_item_sk
              AND wr.wr_return_quantity > 0
              AND wr.wr_returned_time_sk = sw.ws_sold_time_sk
              AND wr.wr_web_page_sk = sw.ws_web_page_sk
        )
)
SELECT
    t_hour,
    wp_type,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_ext_tax) AS avg_tax,
    SUM(COALESCE((
        SELECT SUM(wr.wr_return_amt)
        FROM web_returns wr
        WHERE wr.wr_order_number = fs.ws_order_number
          AND wr.wr_item_sk = fs.ws_item_sk
    ), 0)) AS total_return_amt,
    MIN(ws_net_profit) AS min_profit,
    MAX(ws_net_profit) AS max_profit
FROM filtered_sales fs
GROUP BY t_hour, wp_type
ORDER BY total_sales DESC
LIMIT 100
