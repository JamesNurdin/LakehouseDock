WITH returns_agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_manager,
        cc.cc_city,
        cc.cc_state,
        d.d_date,
        COUNT(cr.cr_order_number) AS total_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COALESCE(cr.cr_item_sk, -1) AS item_sk,
        CONCAT(cc.cc_city, ', ', cc.cc_state) AS city_state
    FROM call_center cc
    FULL OUTER JOIN catalog_returns cr
        ON cc.cc_call_center_sk = cr.cr_call_center_sk
    LEFT JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_manager,
        cc.cc_city,
        cc.cc_state,
        d.d_date,
        COALESCE(cr.cr_item_sk, -1),
        CONCAT(cc.cc_city, ', ', cc.cc_state)
)
SELECT
    ra.cc_call_center_id,
    ra.d_date AS return_date,
    CASE WHEN regexp_like(ra.cc_manager, '^M.*') THEN 1 ELSE 0 END AS manager_name_starts_with_M,
    ra.total_returns,
    ra.total_net_loss,
    ra.avg_return_amount,
    CASE
        WHEN ra.item_sk = -1 THEN NULL
        ELSE (SELECT AVG(cr3.cr_net_loss)
              FROM catalog_returns cr3
              WHERE cr3.cr_item_sk = ra.item_sk)
    END AS item_avg_net_loss,
    CASE
        WHEN ra.total_net_loss > 0 THEN 'Loss'
        WHEN ra.total_net_loss < 0 THEN 'Profit'
        ELSE 'Neutral'
    END AS net_loss_category,
    substring(ra.city_state FROM 1 FOR 5) AS city_prefix,
    CASE
        WHEN ra.total_returns > 10 THEN 'High'
        ELSE 'Low'
    END AS return_volume_category
FROM returns_agg ra
WHERE
    (ra.cc_manager LIKE '%Ray%' OR ra.city_state LIKE 'San%')
    AND ra.total_returns > 0
ORDER BY
    ra.total_net_loss DESC
LIMIT 100
