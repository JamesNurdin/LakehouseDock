/* goal: Identify the most profitable item categories for high‑value customers in California, taking into account inventory levels, promotions, and shipping mode, and rank categories by total profit */
WITH sales_agg AS (
    SELECT
        i.i_category AS i_category,
        i.i_brand   AS i_brand,
        w.w_warehouse_name AS w_warehouse_name,
        sm.sm_type  AS ship_type,
        SUM(ws.ws_net_profit)      AS total_profit,
        SUM(ws.ws_quantity)        AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        CASE WHEN SUM(ws.ws_quantity) > 1000 THEN 'HIGH' ELSE 'LOW' END AS quantity_level
    FROM
        web_sales ws
        JOIN item i
            ON ws.ws_item_sk = i.i_item_sk
        JOIN warehouse w
            ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN ship_mode sm
            ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN promotion p
            ON ws.ws_promo_sk = p.p_promo_sk
            AND p.p_item_sk = i.i_item_sk
        JOIN customer c
            ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
            AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        cd.cd_purchase_estimate >= 5000                -- high‑value customers
        AND cd.cd_dep_count <= 2                       -- small household
        AND i.i_current_price BETWEEN 10 AND 100       -- moderate price range
        AND w.w_state = 'CA'                           -- California warehouses
        AND p.p_discount_active = 'Y'                  -- active promotions
        AND inv.inv_quantity_on_hand > 0               -- items in stock
    GROUP BY
        i.i_category,
        i.i_brand,
        w.w_warehouse_name,
        sm.sm_type
)
SELECT
    sa.i_category,
    SUM(sa.total_profit)                         AS category_profit,
    AVG(sa.total_profit)                         AS avg_brand_profit,
    COUNT(*)                                     AS brand_cnt,
    RANK() OVER (ORDER BY SUM(sa.total_profit) DESC) AS profit_rank,
    CASE WHEN SUM(sa.total_profit) > 50000 THEN 'TOP' ELSE 'OTHER' END AS profit_group,
    (SELECT COUNT(*) FROM promotion p_sub WHERE p_sub.p_channel_demo = 'Y') AS demo_promo_count
FROM
    sales_agg sa
GROUP BY
    sa.i_category
HAVING
    SUM(sa.total_profit) > 10000
ORDER BY
    category_profit DESC
