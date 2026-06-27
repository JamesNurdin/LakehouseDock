WITH web_sales_agg AS (
    SELECT
        i.i_category AS category,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_ext_discount_amt) AS web_discount
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY i.i_category
),
store_sales_agg AS (
    SELECT
        i.i_category AS category,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_ext_discount_amt) AS store_discount
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY i.i_category
),
inventory_agg AS (
    SELECT
        i.i_category AS category,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM inventory inv
    JOIN date_dim d
        ON inv.inv_date_sk = d.d_date_sk
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY i.i_category
)
SELECT
    COALESCE(ws.category, ss.category, inv.category) AS category,
    COALESCE(ws.web_net_profit, 0) + COALESCE(ss.store_net_profit, 0) AS total_net_profit,
    COALESCE(ws.web_quantity, 0) + COALESCE(ss.store_quantity, 0) AS total_quantity_sold,
    COALESCE(ws.web_discount, 0) + COALESCE(ss.store_discount, 0) AS total_discount_amount,
    inv.avg_inventory_on_hand
FROM web_sales_agg ws
FULL OUTER JOIN store_sales_agg ss
    ON ws.category = ss.category
FULL OUTER JOIN inventory_agg inv
    ON COALESCE(ws.category, ss.category) = inv.category
ORDER BY total_net_profit DESC
LIMIT 100
