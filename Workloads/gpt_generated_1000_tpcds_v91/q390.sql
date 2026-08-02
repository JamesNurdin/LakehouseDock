WITH returned_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        CASE
            WHEN ca_refund.ca_state = 'CA' THEN 'California'
            WHEN ca_refund.ca_state = 'NY' THEN 'NewYork'
            ELSE 'Other'
        END AS refund_state_group,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr.wr_return_ship_cost) AS total_ship_cost,
        COUNT(*) AS return_count
    FROM web_returns wr
    RIGHT OUTER JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN customer_address ca_refund
        ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
        AND d.d_month_seq >= 100
        AND d.d_weekend = 'N'
        AND (t.t_hour IS NULL OR t.t_hour BETWEEN 8 AND 17)
        AND (ca_refund.ca_state IS NULL OR ca_refund.ca_state IN ('CA', 'NY'))
        AND (wr.wr_returning_addr_sk IS NULL OR EXISTS (
            SELECT 1
            FROM customer_address ca_ret
            WHERE ca_ret.ca_address_sk = wr.wr_returning_addr_sk
                AND ca_ret.ca_street_type = 'Boulevard'
                AND ca_ret.ca_country = 'United States'
        ))
    GROUP BY d.d_year, d.d_month_seq, t.t_hour,
        CASE
            WHEN ca_refund.ca_state = 'CA' THEN 'California'
            WHEN ca_refund.ca_state = 'NY' THEN 'NewYork'
            ELSE 'Other'
        END
)
SELECT
    agg.d_year,
    agg.d_month_seq,
    agg.refund_state_group,
    AVG(agg.total_return_amount) AS avg_return_amount,
    SUM(agg.total_ship_cost) AS sum_ship_cost,
    SUM(agg.return_count) AS total_returns
FROM returned_agg agg
GROUP BY agg.d_year, agg.d_month_seq, agg.refund_state_group
HAVING SUM(agg.total_return_amount) > 5000
UNION ALL
SELECT
    d2.d_year,
    d2.d_month_seq,
    'AllStates' AS refund_state_group,
    AVG(wr2.wr_return_amt_inc_tax) AS avg_return_amount,
    SUM(wr2.wr_return_ship_cost) AS sum_ship_cost,
    COUNT(*) AS total_returns
FROM date_dim d2
LEFT JOIN web_returns wr2
    ON wr2.wr_returned_date_sk = d2.d_date_sk
WHERE d2.d_year = 2000
    AND d2.d_month_seq = 120
    AND d2.d_weekend = 'N'
    AND (wr2.wr_return_ship_cost IS NOT NULL OR wr2.wr_return_ship_cost IS NULL)
GROUP BY d2.d_year, d2.d_month_seq
LIMIT 100
