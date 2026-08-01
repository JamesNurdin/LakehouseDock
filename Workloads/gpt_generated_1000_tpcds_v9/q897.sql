/* Goal: Compare total net loss from store returns and catalog returns across income bands and states, classifying loss magnitude and listing the top contributors */
WITH store_ret AS (
    SELECT
        ib.ib_income_band_sk       AS income_band_sk,
        ib.ib_lower_bound          AS lower_bound,
        ib.ib_upper_bound          AS upper_bound,
        ca.ca_state                AS state,
        SUM(sr.sr_net_loss)        AS total_net_loss,
        CASE WHEN SUM(sr.sr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, ca.ca_state
),
catalog_ret AS (
    SELECT
        ib.ib_income_band_sk       AS income_band_sk,
        ib.ib_lower_bound          AS lower_bound,
        ib.ib_upper_bound          AS upper_bound,
        ca.ca_state                AS state,
        SUM(cr.cr_net_loss)        AS total_net_loss,
        CASE WHEN SUM(cr.cr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, ca.ca_state
)
SELECT DISTINCT
    src_type,
    income_band,
    state,
    total_net_loss,
    loss_category
FROM (
    SELECT
        'Store'   AS src_type,
        CONCAT(CAST(lower_bound AS VARCHAR), '-', CAST(upper_bound AS VARCHAR)) AS income_band,
        state,
        total_net_loss,
        loss_category
    FROM store_ret
    UNION ALL
    SELECT
        'Catalog' AS src_type,
        CONCAT(CAST(lower_bound AS VARCHAR), '-', CAST(upper_bound AS VARCHAR)) AS income_band,
        state,
        total_net_loss,
        loss_category
    FROM catalog_ret
) combined
ORDER BY total_net_loss DESC
LIMIT 100
