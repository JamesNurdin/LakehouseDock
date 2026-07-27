/*
Goal: Produce a sales‑return performance summary that joins store returns, the date dimension, customer address, and call center tables. The query applies multiple filters, classifies total return amount into levels, ranks divisions by their return totals, and uses GROUPING SETS to show subtotals per year, per division, and overall.
*/
WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        d.d_year,
        d.d_month_seq,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        ca.ca_state,
        ca.ca_city,
        cc.cc_division,
        cc.cc_division_name,
        cc.cc_class,
        cc.cc_market_manager,
        cc.cc_gmt_offset,
        cc.cc_tax_percentage
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001                                 -- predicate 1
      AND sr.sr_return_amt > 10                           -- predicate 2
      AND sr.sr_return_tax >= 1.00                        -- predicate 3
      AND sr.sr_return_quantity BETWEEN 1 AND 5           -- predicate 4
      AND ca.ca_state IN ('CA', 'TX', 'NY')               -- predicate 5
      AND cc.cc_class = 'large'                           -- predicate 6
      AND cc.cc_gmt_offset BETWEEN -5 AND 0               -- predicate 7
),
agg AS (
    SELECT
        d_year,
        cc_division,
        SUM(sr_return_amt)      AS total_return_amt,
        SUM(sr_return_tax)      AS total_return_tax,
        COUNT(*)                AS cnt_returns,
        CASE
            WHEN SUM(sr_return_amt) > 100000 THEN 'High'
            WHEN SUM(sr_return_amt) >  50000 THEN 'Medium'
            ELSE 'Low'
        END                     AS return_level
    FROM base
    GROUP BY GROUPING SETS (
        (d_year, cc_division),   -- detailed rows
        (d_year),                -- yearly subtotals
        (cc_division),           -- division subtotals
        ()                       -- grand total
    )
)
SELECT
    COALESCE(CAST(d_year AS VARCHAR), 'All Years')       AS year,
    COALESCE(CAST(cc_division AS VARCHAR), 'All Divisions') AS division,
    total_return_amt,
    total_return_tax,
    cnt_returns,
    return_level,
    ROW_NUMBER() OVER (PARTITION BY cc_division ORDER BY total_return_amt DESC) AS rn_division
FROM agg
ORDER BY total_return_amt DESC
LIMIT 100
