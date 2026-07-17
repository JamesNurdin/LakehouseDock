WITH promo_channel AS (
    SELECT DISTINCT p_item_sk, p_channel_radio
    FROM promotion
)
SELECT 'Radio' AS promo_channel,
       SUM(cr.cr_return_quantity) AS total_return_qty,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_net_loss) AS total_net_loss
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN promo_channel pc ON pc.p_item_sk = i.i_item_sk
WHERE pc.p_channel_radio = 'Y'
UNION ALL
SELECT 'Non-Radio' AS promo_channel,
       SUM(cr.cr_return_quantity) AS total_return_qty,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_net_loss) AS total_net_loss
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN promo_channel pc ON pc.p_item_sk = i.i_item_sk
WHERE pc.p_channel_radio = 'N'
ORDER BY promo_channel
