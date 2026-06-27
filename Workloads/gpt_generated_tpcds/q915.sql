WITH returns_date AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        cr.cr_call_center_sk,
        cr.cr_returning_cdemo_sk,
        d.d_year,
        d.d_month_seq,
        d.d_date
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
joined AS (
    SELECT
        rd.d_year,
        rd.d_month_seq,
        i.i_category,
        r.r_reason_desc,
        sm.sm_ship_mode_id,
        w.w_warehouse_name,
        cd.cd_gender,
        cc.cc_name AS call_center_name,
        rd.cr_return_quantity,
        rd.cr_return_amount,
        rd.cr_net_loss
    FROM returns_date rd
    JOIN item i
        ON rd.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON rd.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm
        ON rd.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON rd.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN customer_demographics cd
        ON rd.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
        ON rd.cr_call_center_sk = cc.cc_call_center_sk
),
aggregated AS (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        r_reason_desc,
        sm_ship_mode_id,
        w_warehouse_name,
        cd_gender,
        call_center_name,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_return_amount) AS total_return_amt,
        SUM(cr_net_loss) AS total_net_loss,
        AVG(cr_return_amount) AS avg_return_amt
    FROM joined
    GROUP BY
        d_year,
        d_month_seq,
        i_category,
        r_reason_desc,
        sm_ship_mode_id,
        w_warehouse_name,
        cd_gender,
        call_center_name
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    r_reason_desc,
    sm_ship_mode_id,
    w_warehouse_name,
    cd_gender,
    call_center_name,
    total_return_qty,
    total_return_amt,
    total_net_loss,
    avg_return_amt,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_return_amt DESC) AS rank_by_return_amt
FROM aggregated
ORDER BY
    d_year,
    d_month_seq,
    total_return_amt DESC
