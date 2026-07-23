WITH cr_agg AS (
    SELECT
        cr.cr_refunded_addr_sk AS addr_sk,
        SUM(cr.cr_return_amount) AS total_cr_return_amount,
        SUM(cr.cr_net_loss) AS total_cr_net_loss,
        COUNT(*) AS cr_return_count
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    WHERE cr.cr_return_amount > 500
      AND cr.cr_ship_mode_sk IN (2, 7, 12)
      AND sm.sm_carrier = 'UPS'
      AND ca_ref.ca_county = 'Barry County'
      AND cd_ref.cd_dep_count >= 2
      AND cd_ref.cd_gender = 'M'
    GROUP BY cr.cr_refunded_addr_sk
),
sr_agg AS (
    SELECT
        sr.sr_addr_sk AS addr_sk,
        SUM(sr.sr_return_amt) AS total_sr_return_amt,
        SUM(sr.sr_net_loss) AS total_sr_net_loss,
        COUNT(*) AS sr_return_count
    FROM store_returns sr
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    WHERE sr.sr_return_amt > 200
      AND sr.sr_returned_date_sk BETWEEN 2451915 AND 2451930
      AND cd_sr.cd_dep_employed_count >= 1
      AND ca_sr.ca_county = 'Barry County'
    GROUP BY sr.sr_addr_sk
)
SELECT
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    cr_agg.total_cr_return_amount,
    sr_agg.total_sr_return_amt,
    (cr_agg.total_cr_return_amount + sr_agg.total_sr_return_amt) AS combined_return_amount,
    CASE
        WHEN (cr_agg.total_cr_net_loss + sr_agg.total_sr_net_loss) > 0 THEN 'Loss'
        ELSE 'Gain'
    END AS net_loss_category,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY (cr_agg.total_cr_return_amount + sr_agg.total_sr_return_amt) DESC) AS state_return_rank
FROM cr_agg
JOIN sr_agg ON cr_agg.addr_sk = sr_agg.addr_sk
JOIN customer_address ca ON cr_agg.addr_sk = ca.ca_address_sk
ORDER BY state_return_rank
LIMIT 100
