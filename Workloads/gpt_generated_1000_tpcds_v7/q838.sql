WITH agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        td.t_hour,
        td.t_am_pm,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
                         AND ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE inv.inv_quantity_on_hand > 200
      AND i.i_category = 'Electronics'
      AND td.t_am_pm = 'PM'
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_item_id, i.i_product_name, td.t_hour, td.t_am_pm
)
SELECT
    i_item_id,
    i_product_name,
    t_hour,
    t_am_pm,
    total_net_profit,
    total_quantity,
    RANK() OVER (PARTITION BY t_hour ORDER BY total_net_profit DESC) AS profit_rank,
    CASE WHEN total_quantity > 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category
FROM agg
ORDER BY t_hour, profit_rank
