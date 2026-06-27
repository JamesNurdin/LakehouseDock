WITH returns_by_demo AS (
    SELECT
        cc.cc_name AS call_center_name,
        cc.cc_city,
        cc.cc_state,
        d.d_year,
        d.d_moy,
        i.i_category,
        sm.sm_type,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        d.d_year,
        d.d_moy,
        i.i_category,
        sm.sm_type,
        cd.cd_gender,
        cd.cd_marital_status
)
SELECT
    call_center_name,
    cc_city,
    cc_state,
    d_year,
    d_moy,
    i_category,
    sm_type,
    cd_gender,
    cd_marital_status,
    total_return_quantity,
    total_return_amount,
    total_net_loss,
    avg_return_amount
FROM returns_by_demo
ORDER BY total_net_loss DESC
LIMIT 100
