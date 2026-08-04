WITH sales_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE i.i_wholesale_cost > 1.00
      AND w.web_market_manager IN ('David Myers', 'James Brewer')
    GROUP BY ws.ws_item_sk, ws.ws_web_site_sk
),
filtered_set AS (
    SELECT item_sk, web_site_sk, total_sales, total_profit
    FROM (
        SELECT ws_item_sk AS item_sk, ws_web_site_sk AS web_site_sk, total_sales, total_profit
        FROM sales_agg
        WHERE total_sales > 5000
          AND ws_web_site_sk IN (
              SELECT web_site_sk FROM web_site WHERE web_market_manager = 'David Myers'
          )
        INTERSECT
        SELECT ws_item_sk, ws_web_site_sk, total_sales, total_profit
        FROM sales_agg
        WHERE total_profit > 1000
          AND ws_web_site_sk IN (
              SELECT web_site_sk FROM web_site WHERE web_rec_start_date >= DATE '2000-01-01'
          )
    ) intersected
    UNION
    SELECT ws_item_sk, ws_web_site_sk, total_sales, total_profit
    FROM sales_agg
    WHERE total_sales BETWEEN 2000 AND 5000
)
SELECT
    item_sk,
    web_site_sk,
    total_sales,
    total_profit,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
FROM (
    SELECT * FROM filtered_set
    EXCEPT
    SELECT ws_item_sk AS item_sk, ws_web_site_sk AS web_site_sk, total_sales, total_profit
    FROM sales_agg
    WHERE order_cnt < 5
) final_set
