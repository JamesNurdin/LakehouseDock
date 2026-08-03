WITH filtered AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_ship_mode_sk,
        ws.ws_ext_ship_cost,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_order_number,
        i.i_brand,
        i.i_color,
        i.i_product_name
    FROM tpcds.web_sales ws
    FULL OUTER JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_ext_ship_cost > 600
      AND ws.ws_ship_mode_sk IN (1, 8, 16)
      AND i.i_color = 'smoke'
      AND i.i_product_name LIKE 'e%'
)
SELECT
    COALESCE(i_brand, 'Unknown') AS brand,
    i_color,
    ws_ship_mode_sk,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    AVG(ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    CASE WHEN SUM(ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_level
FROM filtered
GROUP BY CUBE (i_brand, i_color, ws_ship_mode_sk)
HAVING SUM(ws_ext_sales_price) IS NOT NULL
