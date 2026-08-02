WITH
    -- Aggregate catalog returns (sampled) before joining to other dimensions
    cr_agg AS (
        SELECT
            cr_reason_sk,
            cr_ship_mode_sk,
            SUM(cr_net_loss) AS total_cr_net_loss,
            COUNT(*) AS cr_cnt
        FROM catalog_returns
        TABLESAMPLE BERNOULLI (10)
        GROUP BY cr_reason_sk, cr_ship_mode_sk
    ),
    -- Aggregate web returns per reason
    wr_agg AS (
        SELECT
            wr_reason_sk,
            SUM(wr_net_loss) AS total_wr_net_loss,
            COUNT(*) AS wr_cnt
        FROM web_returns
        GROUP BY wr_reason_sk
    ),
    -- Distinct condo addresses (used for a DISTINCT requirement)
    distinct_ref_addr AS (
        SELECT DISTINCT
            ca_address_sk,
            ca_city,
            ca_state,
            ca_location_type
        FROM customer_address
        WHERE ca_location_type = 'condo'
    ),
    -- Join catalog_returns to address and household demographics (multiple aliases)
    cr_dim AS (
        SELECT DISTINCT
            cr.cr_reason_sk,
            ca_ref.ca_city,
            ca_ref.ca_state,
            hd_ref.hd_vehicle_count
        FROM catalog_returns cr
        JOIN distinct_ref_addr ca_ref
            ON ca_ref.ca_address_sk = cr.cr_refunded_addr_sk
        JOIN customer_address ca_ret
            ON ca_ret.ca_address_sk = cr.cr_returning_addr_sk
        JOIN household_demographics hd_ref
            ON hd_ref.hd_demo_sk = cr.cr_refunded_hdemo_sk
        JOIN household_demographics hd_ret
            ON hd_ret.hd_demo_sk = cr.cr_returning_hdemo_sk
    ),
    -- Join web_returns to address and household demographics (multiple aliases)
    wr_dim AS (
        SELECT DISTINCT
            wr.wr_reason_sk,
            ca_ref.ca_city,
            ca_ref.ca_state,
            hd_ref.hd_vehicle_count
        FROM web_returns wr
        JOIN distinct_ref_addr ca_ref
            ON ca_ref.ca_address_sk = wr.wr_refunded_addr_sk
        JOIN customer_address ca_ret
            ON ca_ret.ca_address_sk = wr.wr_returning_addr_sk
        JOIN household_demographics hd_ref
            ON hd_ref.hd_demo_sk = wr.wr_refunded_hdemo_sk
        JOIN household_demographics hd_ret
            ON hd_ret.hd_demo_sk = wr.wr_returning_hdemo_sk
    )
SELECT
    r.r_reason_desc,
    sm.sm_type,
    COALESCE(crd.ca_city, wrd.ca_city) AS city,
    COALESCE(crd.ca_state, wrd.ca_state) AS state,
    COALESCE(crd.hd_vehicle_count, wrd.hd_vehicle_count) AS vehicle_count,
    cr_agg.total_cr_net_loss,
    cr_agg.cr_cnt,
    wr_agg.total_wr_net_loss,
    wr_agg.wr_cnt,
    (cr_agg.total_cr_net_loss + wr_agg.total_wr_net_loss) AS combined_net_loss
FROM cr_agg
JOIN reason r
    ON r.r_reason_sk = cr_agg.cr_reason_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cr_agg.cr_ship_mode_sk
LEFT JOIN cr_dim crd
    ON crd.cr_reason_sk = r.r_reason_sk
LEFT JOIN wr_dim wrd
    ON wrd.wr_reason_sk = r.r_reason_sk
LEFT JOIN wr_agg
    ON wr_agg.wr_reason_sk = r.r_reason_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr_ex
    WHERE wr_ex.wr_reason_sk = r.r_reason_sk
      AND wr_ex.wr_net_loss > 5000
)
ORDER BY combined_net_loss DESC
LIMIT 100
