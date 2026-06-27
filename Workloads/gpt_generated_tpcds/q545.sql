-- Return analysis by call center, item category, and refunded‑customer gender
WITH filtered_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_net_loss,
        cr_call_center_sk,
        cr_item_sk,
        cr_refunded_cdemo_sk
    FROM catalog_returns
    WHERE cr_return_quantity > 0
      AND cr_net_loss > 0
)
SELECT
    cc.cc_name,
    cc.cc_state,
    i.i_category,
    cd.cd_gender,
    SUM(fr.cr_net_loss) AS total_net_loss,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_count
FROM filtered_returns fr
JOIN call_center cc ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN item i ON fr.cr_item_sk = i.i_item_sk
JOIN customer_demographics cd ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk
GROUP BY cc.cc_name, cc.cc_state, i.i_category, cd.cd_gender
ORDER BY total_net_loss DESC
LIMIT 50
