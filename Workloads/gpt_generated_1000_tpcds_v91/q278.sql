WITH joined_returns AS (
    SELECT
        ca_refunded.ca_state AS refunded_state,
        ca_refunded.ca_city AS refunded_city,
        ca_refunded.ca_location_type AS refunded_location_type,
        ca_returning.ca_state AS returning_state,
        ca_returning.ca_city AS returning_city,
        ca_returning.ca_location_type AS returning_location_type,
        wr.wr_return_amt,
        wr.wr_refunded_cash,
        wr.wr_return_quantity,
        wr.wr_reversed_charge,
        wr.wr_return_tax,
        wr.wr_returned_date_sk
    FROM web_returns wr
    JOIN customer_address ca_refunded
        ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning
        ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    WHERE
        ca_refunded.ca_state IN ('CA','TX','NY','FL','WA')
        AND ca_refunded.ca_location_type IN ('condo','apartment')
        AND ca_refunded.ca_suite_number LIKE 'Suite %'
        AND ca_refunded.ca_city LIKE 'San%'
        AND wr.wr_return_amt > (SELECT AVG(wr2.wr_return_amt) FROM web_returns wr2)
        AND wr.wr_return_quantity > 0
        AND wr.wr_reversed_charge > 10
        AND wr.wr_refunded_cash BETWEEN 100 AND 500
),
aggregated AS (
    SELECT
        refunded_state,
        refunded_city,
        refunded_location_type,
        COUNT(*) AS returns_cnt,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_refunded_cash) AS total_refunded_cash,
        AVG(wr_return_amt) AS avg_return_amt,
        SUM(wr_return_quantity) AS total_return_qty
    FROM joined_returns
    GROUP BY GROUPING SETS (
        (refunded_state, refunded_city, refunded_location_type),
        (refunded_state, refunded_city),
        (refunded_state),
        ()
    )
)
SELECT
    refunded_state,
    refunded_city,
    refunded_location_type,
    returns_cnt,
    total_return_amt,
    total_refunded_cash,
    avg_return_amt,
    total_return_qty,
    SUM(total_return_amt) OVER (PARTITION BY refunded_state) AS state_total_return_amt,
    ROW_NUMBER() OVER (ORDER BY total_return_amt DESC) AS rn,
    (SELECT COUNT(*) FROM web_returns) AS total_wr_rows
FROM aggregated
WHERE
    NOT (refunded_state IS NULL AND refunded_city IS NULL AND refunded_location_type IS NULL)
    AND total_return_amt > 0
ORDER BY
    refunded_state,
    refunded_city,
    refunded_location_type
