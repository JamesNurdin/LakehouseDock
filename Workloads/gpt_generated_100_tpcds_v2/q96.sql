WITH sales_agg AS (
    SELECT
        w.w_warehouse_name,
        d.d_year,
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
        SUM(cs.cs_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0)) AS net_profit,
        SUM(cs.cs_quantity) AS total_quantity_sold
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2001
      AND p.p_discount_active = 'Y'
    GROUP BY w.w_warehouse_name, d.d_year, p.p_promo_name
),
inventory_agg AS (
    SELECT
        w2.w_warehouse_name,
        d2.d_year,
        AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM inventory i
    JOIN date_dim d2 ON i.inv_date_sk = d2.d_date_sk
    JOIN warehouse w2 ON i.inv_warehouse_sk = w2.w_warehouse_sk
    WHERE d2.d_year BETWEEN 2000 AND 2001
    GROUP BY w2.w_warehouse_name, d2.d_year
)
SELECT
    sa.w_warehouse_name,
    sa.d_year,
    sa.p_promo_name,
    sa.total_sales_profit,
    sa.total_return_loss,
    sa.net_profit,
    sa.total_quantity_sold,
    ia.avg_inventory_on_hand
FROM sales_agg sa
JOIN inventory_agg ia
    ON sa.w_warehouse_name = ia.w_warehouse_name
    AND sa.d_year = ia.d_year
ORDER BY sa.net_profit DESC
