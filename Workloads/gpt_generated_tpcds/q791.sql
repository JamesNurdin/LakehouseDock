WITH all_returns AS (
    SELECT i.i_brand,
           i.i_category,
           cr.cr_return_amount AS return_amount,
           cr.cr_net_loss      AS net_loss,
           'catalog'           AS channel
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk

    UNION ALL

    SELECT i.i_brand,
           i.i_category,
           sr.sr_return_amt AS return_amount,
           sr.sr_net_loss   AS net_loss,
           'store'          AS channel
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk

    UNION ALL

    SELECT i.i_brand,
           i.i_category,
           wr.wr_return_amt AS return_amount,
           wr.wr_net_loss   AS net_loss,
           'web'            AS channel
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
)
SELECT i_brand,
       i_category,
       channel,
       SUM(return_amount) AS total_return_amount,
       SUM(net_loss)      AS total_net_loss,
       COUNT(*)           AS return_cnt
FROM all_returns
GROUP BY i_brand, i_category, channel
ORDER BY total_return_amount DESC
LIMIT 20
