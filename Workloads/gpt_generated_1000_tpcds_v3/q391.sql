WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 20
      AND i.i_manager_id IN (27, 40)
      AND ws.ws_ext_discount_amt > 500
    GROUP BY i.i_item_sk, i.i_product_name, i.i_category
)
SELECT
    i_category,
    i_product_name,
    total_profit,
    total_quantity,
    avg_discount,
    CASE WHEN total_profit > 10000 THEN 'High'
         WHEN total_profit > 5000 THEN 'Medium'
         ELSE 'Low' END AS profit_category,
    RANK() OVER (PARTITION BY i_category ORDER BY total_profit DESC) AS profit_rank
FROM item_sales
ORDER BY i_category, profit_rank
