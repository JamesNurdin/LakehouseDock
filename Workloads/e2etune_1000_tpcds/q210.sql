WITH category_sales AS (
    SELECT i.i_category AS category,
           SUM(cs.cs_net_profit) AS total_net_profit,
           COUNT(DISTINCT cs.cs_order_number) AS num_orders,
           AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE cs.cs_net_paid_inc_ship > 2000
    GROUP BY i.i_category
),
category_returns AS (
    SELECT i.i_category,
           SUM(wr.wr_return_quantity) AS total_return_qty,
           SUM(wr.wr_net_loss) AS total_return_loss,
           r.r_reason_desc,
           COUNT(*) AS reason_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_quantity > 0
    GROUP BY i.i_category, r.r_reason_desc
),
category_top_reason AS (
    SELECT i_category,
           r_reason_desc AS top_reason,
           reason_cnt
    FROM (
        SELECT i_category,
               r_reason_desc,
               reason_cnt,
               ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY reason_cnt DESC) AS rn
        FROM category_returns
    ) sub
    WHERE rn = 1
)
SELECT cs.category,
       cs.total_net_profit,
       cs.num_orders,
       cs.avg_inventory_on_hand,
       cr.total_return_qty,
       cr.total_return_loss,
       tr.top_reason
FROM category_sales cs
LEFT JOIN (
    SELECT i_category,
           SUM(total_return_qty) AS total_return_qty,
           SUM(total_return_loss) AS total_return_loss
    FROM category_returns
    GROUP BY i_category
) cr ON cs.category = cr.i_category
LEFT JOIN category_top_reason tr ON cs.category = tr.i_category
WHERE cs.total_net_profit > 0
ORDER BY cs.total_net_profit DESC
LIMIT 10
