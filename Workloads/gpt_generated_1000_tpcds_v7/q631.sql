WITH sales_huron AS (
    SELECT
        i.i_category AS category,
        w.w_county AS county,
        SUM(ws.ws_net_profit) AS profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_county = 'Huron County'
      AND ws.ws_ext_sales_price > 5000
    GROUP BY i.i_category, w.w_county
),
sales_san_miguel AS (
    SELECT
        i.i_category AS category,
        w.w_county AS county,
        SUM(ws.ws_net_profit) AS profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_county = 'San Miguel County'
      AND ws.ws_ext_sales_price <= 2000
    GROUP BY i.i_category, w.w_county
)
SELECT category,
       county,
       profit,
       order_cnt
FROM sales_huron
UNION ALL
SELECT category,
       county,
       profit,
       order_cnt
FROM sales_san_miguel
ORDER BY category, profit DESC
