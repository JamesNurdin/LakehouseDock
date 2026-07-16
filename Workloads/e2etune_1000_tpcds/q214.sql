WITH latest_inventory AS (
    SELECT
        inv_item_sk,
        inv_quantity_on_hand,
        inv_date_sk,
        ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) AS rn
    FROM inventory
),
sales_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(li.inv_quantity_on_hand) AS total_latest_inventory
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN latest_inventory li ON li.inv_item_sk = i.i_item_sk AND li.rn = 1
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451053
      AND i.i_current_price > 20.00
    GROUP BY i.i_category, i.i_brand
    HAVING SUM(ws.ws_quantity) > 1000
)
SELECT
    i_category,
    i_brand,
    total_net_profit,
    avg_discount_amt,
    total_quantity_sold,
    total_latest_inventory,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 20
