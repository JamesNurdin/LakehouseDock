WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
),
sales_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        w.w_city,
        w.w_state,
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_sold
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'Y'
      AND ws.ws_sold_date_sk BETWEEN 2459000 AND 2459029
    GROUP BY ws.ws_warehouse_sk, w.w_city, w.w_state, p.p_promo_name
)
SELECT
    s.ws_warehouse_sk,
    s.w_city,
    s.w_state,
    s.p_promo_name,
    s.total_net_profit,
    s.total_quantity_sold,
    s.avg_discount_amt,
    s.distinct_items_sold,
    COALESCE(i.total_inventory_on_hand, 0) AS total_inventory_on_hand,
    RANK() OVER (ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN inv_agg i ON s.ws_warehouse_sk = i.inv_warehouse_sk
ORDER BY profit_rank
LIMIT 5
