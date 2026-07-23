WITH
    item_inventory AS (
        SELECT inv_item_sk,
               SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        GROUP BY inv_item_sk
        HAVING SUM(inv_quantity_on_hand) > 0
    ),
    sales_metrics AS (
        SELECT i.i_item_id,
               i.i_product_name,
               'sales' AS metric_type,
               SUM(ss.ss_net_profit) AS metric_value
        FROM store_sales ss
        INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
        INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
        INNER JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        INNER JOIN item_inventory inv ON i.i_item_sk = inv.inv_item_sk
        WHERE s.s_state = 'CA'
          AND i.i_current_price > 10
        GROUP BY i.i_item_id,
                 i.i_product_name
    ),
    return_metrics AS (
        SELECT i.i_item_id,
               i.i_product_name,
               'return' AS metric_type,
               SUM(sr.sr_net_loss) AS metric_value
        FROM store_returns sr
        INNER JOIN item i ON sr.sr_item_sk = i.i_item_sk
        INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
        INNER JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        INNER JOIN item_inventory inv ON i.i_item_sk = inv.inv_item_sk
        WHERE s.s_state = 'CA'
          AND sr.sr_return_quantity > 0
        GROUP BY i.i_item_id,
                 i.i_product_name
    ),
    combined AS (
        SELECT i_item_id,
               i_product_name,
               metric_type,
               metric_value
        FROM sales_metrics
        UNION ALL
        SELECT i_item_id,
               i_product_name,
               metric_type,
               metric_value
        FROM return_metrics
    )
SELECT c.i_item_id,
       c.i_product_name,
       c.metric_type,
       c.metric_value,
       ROW_NUMBER() OVER (PARTITION BY c.metric_type ORDER BY c.metric_value DESC) AS rank,
       (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS overall_avg_net_profit
FROM combined c
ORDER BY c.metric_type,
         rank
LIMIT 100
