WITH latest_inv AS (
    SELECT inv_item_sk,
           MAX(inv_date_sk) AS latest_date,
           SUM(inv_quantity_on_hand) AS qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    SUM(ws.ws_quantity) AS total_units_sold,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(CASE WHEN ws.ws_ext_list_price > 0 THEN ws.ws_ext_discount_amt / ws.ws_ext_list_price ELSE 0 END) AS avg_discount_rate,
    MAX(li.qty_on_hand) AS inventory_on_hand_latest,
    DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_dense_rank,
    CASE
        WHEN SUM(ws.ws_net_profit) >= 100000 THEN 'Platinum'
        WHEN SUM(ws.ws_net_profit) >= 50000 THEN 'Gold'
        WHEN SUM(ws.ws_net_profit) >= 20000 THEN 'Silver'
        ELSE 'Bronze'
    END AS profit_tier,
    CASE
        WHEN AVG(CASE WHEN ws.ws_ext_list_price > 0 THEN ws.ws_ext_discount_amt / ws.ws_ext_list_price ELSE 0 END) > 0.2 THEN 'High Discount'
        ELSE 'Low/Medium Discount'
    END AS discount_flag,
    AVG(ws.ws_ext_sales_price) FILTER (WHERE td.t_shift = 'Evening') AS avg_evening_sales_price,
    AVG(ws.ws_ext_sales_price) FILTER (WHERE td.t_shift = 'Morning') AS avg_morning_sales_price
FROM web_sales ws
INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
INNER JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
LEFT JOIN latest_inv li ON i.i_item_sk = li.inv_item_sk
GROUP BY i.i_item_id, i.i_product_name, i.i_brand, i.i_category, li.qty_on_hand
HAVING SUM(ws.ws_quantity) > 0
ORDER BY total_profit DESC
LIMIT 50
