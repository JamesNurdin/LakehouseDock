WITH sales_data AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_item_id,
        i.i_manager_id,
        cc.cc_name,
        sm.sm_type,
        cd.cd_gender,
        cs.cs_net_paid AS amount,
        cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_units = 'Case'
      AND i.i_manager_id IN (23, 25)
      AND sm.sm_type = 'AIR'
      AND cs.cs_sold_date_sk BETWEEN 2452020 AND 2452029
      AND cd.cd_credit_rating = 'A'
),
returns_data AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_item_id,
        i.i_manager_id,
        cc.cc_name,
        sm.sm_type,
        cd.cd_gender,
        cr.cr_return_amount AS amount,
        cr.cr_return_quantity AS quantity
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_units = 'Case'
      AND i.i_manager_id IN (23, 25)
      AND sm.sm_type = 'AIR'
      AND cr.cr_returned_date_sk BETWEEN 2452020 AND 2452029
      AND cd.cd_credit_rating = 'A'
),
combined AS (
    SELECT * FROM sales_data
    UNION ALL
    SELECT * FROM returns_data
)
SELECT
    combined.i_item_id,
    combined.i_manager_id,
    combined.cc_name,
    combined.sm_type,
    combined.cd_gender,
    inv.total_on_hand,
    SUM(combined.amount) AS total_amount,
    AVG(combined.amount) AS avg_amount,
    MIN(combined.amount) AS min_amount,
    MAX(combined.amount) AS max_amount,
    SUM(combined.quantity) AS total_quantity,
    COUNT(*) AS record_count
FROM combined
CROSS JOIN LATERAL (
    SELECT SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_item_sk = combined.item_sk
) AS inv
WHERE inv.total_on_hand > 500
GROUP BY
    combined.i_item_id,
    combined.i_manager_id,
    combined.cc_name,
    combined.sm_type,
    combined.cd_gender,
    inv.total_on_hand
ORDER BY total_amount DESC
LIMIT 100
