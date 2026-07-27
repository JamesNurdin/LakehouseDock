WITH date_filtered AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year IN (2000, 2001)
)
SELECT *
FROM (
    SELECT
        sm.sm_ship_mode_id AS ship_mode,
        CASE WHEN hd.hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS vehicle_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_net_loss) AS avg_net_loss,
        'DidNotLike' AS reason_group
    FROM catalog_returns cr
    JOIN date_filtered df ON cr.cr_returned_date_sk = df.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%Did not like%'
      AND EXISTS (
          SELECT 1
          FROM customer_address ca
          WHERE ca.ca_address_sk = cr.cr_refunded_addr_sk
            AND ca.ca_state = 'CA'
      )
    GROUP BY sm.sm_ship_mode_id,
             CASE WHEN hd.hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END

    UNION ALL

    SELECT
        sm.sm_ship_mode_id AS ship_mode,
        CASE WHEN hd.hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS vehicle_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_net_loss) AS avg_net_loss,
        'PartsMissing' AS reason_group
    FROM catalog_returns cr
    JOIN date_filtered df ON cr.cr_returned_date_sk = df.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%Parts missing%'
      AND df.d_year = 2001
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
    GROUP BY sm.sm_ship_mode_id,
             CASE WHEN hd.hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
