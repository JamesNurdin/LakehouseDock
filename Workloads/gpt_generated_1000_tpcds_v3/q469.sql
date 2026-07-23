WITH store_ret AS (
    SELECT
        sr.sr_item_sk AS item_sk,
        SUM(sr.sr_net_loss) AS net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE s.s_state = 'CA'
    GROUP BY sr.sr_item_sk
),
catalog_ret AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_net_loss) AS net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cc.cc_state = 'CA'
    GROUP BY cr.cr_item_sk
),
combined AS (
    SELECT item_sk, net_loss, return_cnt FROM store_ret
    UNION ALL
    SELECT item_sk, net_loss, return_cnt FROM catalog_ret
)
SELECT
    i.i_item_id,
    i.i_product_name,
    SUM(c.net_loss) AS total_net_loss,
    SUM(c.return_cnt) AS total_returns,
    COUNT(DISTINCT i.i_brand) AS distinct_brands
FROM combined c
JOIN item i ON c.item_sk = i.i_item_sk
WHERE EXISTS (
    SELECT 1 FROM promotion p
    WHERE p.p_item_sk = i.i_item_sk
      AND p.p_discount_active = 'Y'
)
GROUP BY i.i_item_id, i.i_product_name
HAVING SUM(c.net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
