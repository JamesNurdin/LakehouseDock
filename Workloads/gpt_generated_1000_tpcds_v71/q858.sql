WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        d.d_date,
        d.d_year,
        cc.cc_call_center_id,
        cc.cc_state,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        sm.sm_code,
        c.c_customer_id,
        c.c_birth_year,
        ca.ca_state AS addr_state,
        cd.cd_gender,
        cr.cr_return_amount
    FROM catalog_returns cr
    INNER JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    INNER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    INNER JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND cc.cc_state = 'CA'
      AND sm.sm_carrier = 'DHL'
      AND cd.cd_gender = 'M'
),
agg AS (
    SELECT
        b.c_customer_id,
        b.d_year,
        SUM(b.cr_return_amount) AS total_return_amount
    FROM base b
    GROUP BY b.c_customer_id, b.d_year
)
SELECT
    a.c_customer_id,
    a.d_year,
    a.total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_return_amount DESC) AS rn_yearly,
    CASE
        WHEN a.total_return_amount > (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
            INNER JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
            WHERE d2.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS amount_vs_avg
FROM agg a
WHERE a.total_return_amount > 1000
ORDER BY a.d_year, rn_yearly
