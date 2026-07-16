WITH inv_agg AS (
    SELECT inv_item_sk, SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    cc.cc_name AS call_center,
    i.i_category AS category,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_refunded_cash) AS avg_refunded_cash,
    inv_agg.total_on_hand,
    RANK() OVER (PARTITION BY cc.cc_name ORDER BY SUM(cr.cr_net_loss) DESC) AS net_loss_rank
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
WHERE cc.cc_class = 'large'
  AND cc.cc_employees > 2000000
  AND i.i_category <> ''
GROUP BY cc.cc_name, i.i_category, inv_agg.total_on_hand
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 50
