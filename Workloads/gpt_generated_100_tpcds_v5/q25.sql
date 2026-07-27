WITH filtered_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_return_quantity,
        d.d_year,
        d.d_day_name,
        sm.sm_carrier,
        sm.sm_type,
        cd_ref.cd_gender AS refunded_gender,
        cd_ret.cd_gender AS returning_gender,
        CASE 
            WHEN cr.cr_fee > 90 THEN 'HIGH'
            WHEN cr.cr_fee > 70 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS fee_category
    FROM catalog_returns AS cr
    JOIN date_dim AS d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics AS cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics AS cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN ship_mode AS sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 1911
      AND d.d_day_name = 'Monday'
      AND sm.sm_carrier = 'MSC'
      AND sm.sm_type = 'EXPRESS'
      AND cr.cr_fee > 50
      AND cr.cr_return_amount >= 20
      AND cd_ref.cd_gender = 'F'
      AND cd_ret.cd_gender = 'M'
),
agg_returns AS (
    SELECT
        d_year,
        sm_carrier,
        sm_type,
        fee_category,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM filtered_returns
    GROUP BY d_year, sm_carrier, sm_type, fee_category
)
SELECT
    d_year,
    sm_carrier,
    sm_type,
    fee_category,
    total_return_amount,
    return_cnt,
    RANK() OVER (ORDER BY total_return_amount DESC) AS carrier_return_rank
FROM agg_returns
ORDER BY carrier_return_rank, d_year
LIMIT 100
