WITH avg_cr_net_loss AS (
    SELECT avg(cr_net_loss) AS avg_loss
    FROM catalog_returns
)
SELECT
    'catalog' AS return_channel,
    i.i_item_id,
    i.i_product_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    CASE
        WHEN SUM(cr.cr_net_loss) > (SELECT avg_loss FROM avg_cr_net_loss) THEN 'High'
        ELSE 'Low'
    END AS loss_category
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
WHERE p.p_channel_tv = 'N'
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_response_target > 1
    )
GROUP BY i.i_item_id, i.i_product_name

UNION ALL

SELECT
    'web' AS return_channel,
    i.i_item_id,
    i.i_product_name,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    CASE
        WHEN SUM(wr.wr_net_loss) > (SELECT avg_loss FROM avg_cr_net_loss) THEN 'High'
        ELSE 'Low'
    END AS loss_category
FROM web_returns wr
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_type = 'product'
GROUP BY i.i_item_id, i.i_product_name

ORDER BY total_net_loss DESC, return_channel
LIMIT 100
