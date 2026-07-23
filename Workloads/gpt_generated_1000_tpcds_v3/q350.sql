WITH raw_returns AS (
    SELECT
        ca_refunded.ca_address_sk AS refunded_address_sk,
        ca_refunded.ca_state AS refunded_state,
        ca_refunded.ca_city AS refunded_city,
        ca_refunded.ca_location_type AS refunded_location_type,
        ca_refunded.ca_suite_number AS refunded_suite,
        ca_returning.ca_address_sk AS returning_address_sk,
        ca_returning.ca_state AS returning_state,
        ca_returning.ca_city AS returning_city,
        ca_returning.ca_location_type AS returning_location_type,
        ca_returning.ca_suite_number AS returning_suite,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_amt_inc_tax,
        wr.wr_fee,
        wr.wr_return_ship_cost,
        wr.wr_refunded_cash,
        wr.wr_net_loss,
        wr.wr_returned_date_sk
    FROM web_returns wr
    JOIN customer_address ca_refunded
        ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning
        ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    WHERE
        wr.wr_return_amt > 200
        AND wr.wr_fee BETWEEN 10 AND 50
        AND wr.wr_return_quantity >= 1
        AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
        AND ca_refunded.ca_location_type = 'apartment'
        AND ca_returning.ca_state IN ('CA', 'TX', 'NY')
        AND ca_refunded.ca_gmt_offset >= -5.00
        AND ca_refunded.ca_suite_number LIKE 'Suite %'
),
per_refunded_address AS (
    SELECT
        refunded_address_sk,
        refunded_state,
        refunded_city,
        refunded_location_type,
        refunded_suite,
        COUNT(*) AS num_returns,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(wr_fee) AS total_fee,
        SUM(wr_net_loss) AS total_net_loss,
        AVG(wr_return_amt) AS avg_return_amt
    FROM raw_returns
    GROUP BY
        refunded_address_sk,
        refunded_state,
        refunded_city,
        refunded_location_type,
        refunded_suite
),
state_agg AS (
    SELECT
        refunded_state,
        COUNT(DISTINCT refunded_address_sk) AS distinct_refunded_addresses,
        SUM(total_return_amt) AS state_total_return_amt,
        AVG(total_return_amt) AS avg_address_return_amt,
        SUM(total_net_loss) AS state_total_net_loss
    FROM per_refunded_address
    GROUP BY refunded_state
    HAVING SUM(total_return_amt) > 1000
)
SELECT
    s.refunded_state,
    s.distinct_refunded_addresses,
    s.state_total_return_amt,
    s.avg_address_return_amt,
    s.state_total_net_loss,
    ROW_NUMBER() OVER (ORDER BY s.state_total_return_amt DESC) AS state_rank,
    (SELECT AVG(state_total_return_amt) FROM state_agg) AS overall_avg_state_return,
    (SELECT ARRAY_AGG(DISTINCT refunded_state)
     FROM state_agg sa
     WHERE sa.avg_address_return_amt > (SELECT AVG(state_total_return_amt) FROM state_agg)
    ) AS states_above_overall_avg
FROM state_agg s
WHERE s.state_total_net_loss > 500
ORDER BY s.state_total_return_amt DESC
LIMIT 100
