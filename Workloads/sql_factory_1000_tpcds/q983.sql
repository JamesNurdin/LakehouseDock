SELECT 
    i.i_item_sk,
    i.i_product_name,
    i.i_category,
    i.i_current_price,
    t.total_net_loss,
    t.return_cnt,
    t.loss_rank
FROM (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        RANK() OVER (ORDER BY SUM(cr.cr_net_loss) DESC) AS loss_rank
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
) t
JOIN item i ON t.cr_item_sk = i.i_item_sk
WHERE t.loss_rank <= 5
ORDER BY t.loss_rank
