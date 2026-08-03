WITH
    -- Join all five tables in a left‑deep chain and apply several filters
    joined_data AS (
        SELECT
            ca.ca_state,
            td.t_hour,
            sr.sr_net_loss,
            cr.cr_net_loss,
            wr.wr_net_loss
        FROM catalog_returns cr
        JOIN time_dim td
            ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN store_returns sr
            ON sr.sr_return_time_sk = td.t_time_sk
        JOIN customer_address ca
            ON sr.sr_addr_sk = ca.ca_address_sk
            AND cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN web_returns wr
            ON wr.wr_returned_time_sk = td.t_time_sk
            AND wr.wr_refunded_addr_sk = ca.ca_address_sk
        WHERE
            sr.sr_return_ship_cost > 100.00                     -- predicate 1
            AND cr.cr_return_amount > 50.00                      -- predicate 2
            AND wr.wr_return_amt > 30.00                         -- predicate 3
            AND td.t_hour BETWEEN 10 AND 15                     -- predicate 4
            AND ca.ca_state = 'CA'                               -- predicate 5
            AND ca.ca_suite_number LIKE 'Suite %'                -- predicate 6
            AND td.t_minute % 2 = 0                              -- predicate 7
    ),
    -- Aggregate per state and hour
    state_hour_agg AS (
        SELECT
            ca_state,
            t_hour,
            SUM(sr_net_loss) AS sum_sr_loss,
            SUM(cr_net_loss) AS sum_cr_loss,
            SUM(wr_net_loss) AS sum_wr_loss,
            COUNT(*) AS cnt_rows
        FROM joined_data
        GROUP BY ca_state, t_hour
    ),
    -- Small dimension for cross‑join (threshold values)
    thresholds AS (
        SELECT 100.0 AS loss_thresh UNION ALL SELECT 200.0 UNION ALL SELECT 300.0
    ),
    -- Cross join aggregated data with thresholds and flag rows exceeding a threshold
    agg_with_thresh AS (
        SELECT
            a.ca_state,
            a.t_hour,
            a.sum_sr_loss,
            a.sum_cr_loss,
            a.sum_wr_loss,
            t.loss_thresh,
            CASE WHEN a.sum_sr_loss + a.sum_cr_loss + a.sum_wr_loss > t.loss_thresh THEN 1 ELSE 0 END AS exceed_flag
        FROM state_hour_agg a
        CROSS JOIN thresholds t
    ),
    -- Union distinct of two loss extracts (store vs. web) after the flag
    union_losses AS (
        SELECT ca_state, sum_sr_loss AS total_loss FROM agg_with_thresh WHERE exceed_flag = 1
        UNION DISTINCT
        SELECT ca_state, sum_wr_loss AS total_loss FROM agg_with_thresh WHERE exceed_flag = 1
    ),
    -- Subqueries to intersect address keys from store and web returns
    store_addresses AS (
        SELECT DISTINCT sr_addr_sk FROM store_returns
    ),
    web_addresses AS (
        SELECT DISTINCT wr_refunded_addr_sk FROM web_returns
    ),
    common_addresses AS (
        SELECT sr_addr_sk FROM store_addresses INTERSECT SELECT wr_refunded_addr_sk FROM web_addresses
    )
SELECT
    u.ca_state,
    AVG(u.total_loss) AS avg_total_loss,
    COUNT(*) AS num_states
FROM union_losses u
WHERE u.ca_state IN (SELECT ca_state FROM customer_address WHERE ca_state = 'CA')
GROUP BY u.ca_state
HAVING AVG(u.total_loss) > 150
ORDER BY avg_total_loss DESC
LIMIT 100
