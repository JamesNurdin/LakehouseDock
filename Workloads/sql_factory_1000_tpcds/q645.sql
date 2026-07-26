WITH latest_inv AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           inv_quantity_on_hand
    FROM (
        SELECT inv_item_sk,
               inv_warehouse_sk,
               inv_quantity_on_hand,
               ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) AS rn
        FROM inventory
    ) t
    WHERE rn = 1
)
SELECT
    i.i_category,
    td.t_shift,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(CASE WHEN ws.ws_ext_list_price > 0 THEN ws.ws_ext_discount_amt / ws.ws_ext_list_price ELSE 0 END) AS avg_discount_rate,
    MAX(li.inv_quantity_on_hand) AS inventory_on_hand_latest,
    RANK() OVER (PARTITION BY td.t_shift ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank_in_shift,
    CASE
        WHEN SUM(ws.ws_net_profit) > 1000000 THEN 'High'
        WHEN SUM(ws.ws_net_profit) > 500000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_tier
FROM web_sales ws
INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
INNER JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
LEFT JOIN latest_inv li ON i.i_item_sk = li.inv_item_sk
GROUP BY i.i_category, td.t_shift
ORDER BY i.i_category, total_profit DESC
LIMIT 20
