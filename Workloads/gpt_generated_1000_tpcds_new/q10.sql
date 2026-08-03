WITH item_returns AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_class_id,
        i.i_manufact,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
        COUNT(DISTINCT wr.wr_order_number) AS web_orders,
        MIN(p.p_cost) AS promo_min_cost,
        MAX(p.p_cost) AS promo_max_cost
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 100
      AND cr.cr_return_quantity > 1
      AND p.p_cost BETWEEN 500 AND 2000
      AND i.i_class_id IN (7, 12, 15, 14)
      AND wp.wp_type = 'product'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_class_id, i.i_manufact
)
SELECT
    ir.i_item_id,
    ir.i_product_name,
    ir.i_class_id,
    ir.i_manufact,
    ir.catalog_net_loss,
    ir.web_net_loss,
    (ir.catalog_net_loss + ir.web_net_loss) AS total_net_loss,
    RANK() OVER (ORDER BY (ir.catalog_net_loss + ir.web_net_loss) DESC) AS loss_rank,
    CASE
        WHEN (ir.catalog_net_loss + ir.web_net_loss) > 1000 THEN 'High'
        WHEN (ir.catalog_net_loss + ir.web_net_loss) BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category
FROM item_returns ir
ORDER BY loss_rank
LIMIT 100
