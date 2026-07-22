WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
),
warehouse_item_stats AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        i.i_brand,
        i.i_brand_id,
        SUM(cs.cs_net_paid) AS total_sales_net_paid,
        SUM(cs.cs_net_profit) AS total_sales_net_profit,
        SUM(cr.cr_net_loss) AS total_return_net_loss,
        inv_agg.total_qty_on_hand
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
        AND cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inv_agg
        ON i.i_item_sk = inv_agg.inv_item_sk
        AND w.w_warehouse_sk = inv_agg.inv_warehouse_sk
    WHERE
        inv_agg.total_qty_on_hand > 500
        AND i.i_brand_id IN (1004002, 2004001)
        AND r.r_reason_desc LIKE '%price%'
    GROUP BY
        w.w_warehouse_id,
        w.w_warehouse_name,
        i.i_brand,
        i.i_brand_id,
        inv_agg.total_qty_on_hand
)
SELECT
    w_id,
    w_name,
    brand,
    brand_id,
    total_sales_net_paid,
    total_sales_net_profit,
    total_return_net_loss,
    (total_sales_net_profit - total_return_net_loss) AS net_profit_after_returns,
    total_qty_on_hand,
    ROW_NUMBER() OVER (PARTITION BY brand ORDER BY (total_sales_net_profit - total_return_net_loss) DESC) AS brand_warehouse_rank,
    (SELECT AVG(total_sales_net_profit - total_return_net_loss) FROM warehouse_item_stats) AS overall_avg_net_profit
FROM (
    SELECT
        w_warehouse_id AS w_id,
        w_warehouse_name AS w_name,
        i_brand AS brand,
        i_brand_id AS brand_id,
        total_sales_net_paid,
        total_sales_net_profit,
        total_return_net_loss,
        total_qty_on_hand
    FROM warehouse_item_stats
) w
WHERE (total_sales_net_profit - total_return_net_loss) > (
    SELECT AVG(total_sales_net_profit - total_return_net_loss)
    FROM warehouse_item_stats
)
ORDER BY net_profit_after_returns DESC
LIMIT 100
