WITH promo_sales AS (
    SELECT
        ws.ws_promo_sk,
        ws.ws_item_sk,
        ws.ws_warehouse_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    GROUP BY ws.ws_promo_sk, ws.ws_item_sk, ws.ws_warehouse_sk
),
 item_inventory AS (
    SELECT
        i.inv_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_stock
    FROM inventory i
    GROUP BY i.inv_item_sk
),
 promo_analysis AS (
    SELECT
        ps.ws_promo_sk,
        ps.ws_item_sk,
        ps.ws_warehouse_sk,
        ps.total_profit,
        ps.total_quantity,
        ps.avg_discount,
        ps.distinct_customers,
        COALESCE(ii.total_stock, 0) AS total_stock,
        CASE
            WHEN ps.total_quantity > COALESCE(ii.total_stock, 0) THEN 'Shortage'
            ELSE 'Sufficient'
        END AS stock_status,
        CASE
            WHEN ps.total_quantity = 0 THEN NULL
            ELSE ps.total_profit / NULLIF(ps.total_quantity, 0)
        END AS profit_per_unit
    FROM promo_sales ps
    LEFT JOIN item_inventory ii
        ON ps.ws_item_sk = ii.inv_item_sk
),
 top_bill_customer_per_promo AS (
    SELECT
        ws.ws_promo_sk,
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS qty,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_promo_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rn
    FROM web_sales ws
    GROUP BY ws.ws_promo_sk, ws.ws_bill_customer_sk
),
 promo_with_customer AS (
    SELECT
        pa.*,
        tbc.ws_bill_customer_sk
    FROM promo_analysis pa
    LEFT JOIN top_bill_customer_per_promo tbc
        ON pa.ws_promo_sk = tbc.ws_promo_sk
        AND tbc.rn = 1
)
SELECT
    pwp.ws_promo_sk,
    pwp.ws_item_sk,
    w.w_warehouse_name,
    pwp.total_profit,
    pwp.total_quantity,
    pwp.avg_discount,
    pwp.total_stock,
    pwp.stock_status,
    pwp.profit_per_unit,
    RANK() OVER (ORDER BY pwp.profit_per_unit DESC) AS profit_per_unit_rank,
    CASE
        WHEN pwp.avg_discount > 0.20 THEN 'High Discount'
        WHEN pwp.avg_discount > 0.10 THEN 'Medium Discount'
        ELSE 'Low Discount'
    END AS discount_category,
    c.c_first_name || ' ' || c.c_last_name AS top_bill_customer_name,
    pwp.distinct_customers
FROM promo_with_customer pwp
LEFT JOIN warehouse w
    ON pwp.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN customer c
    ON pwp.ws_bill_customer_sk = c.c_customer_sk
WHERE pwp.total_quantity > 0
ORDER BY profit_per_unit_rank
