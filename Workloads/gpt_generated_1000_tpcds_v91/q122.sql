WITH filtered AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_company,
        cc.cc_division_name,
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_refunded_cash,
        d.d_year,
        d.d_quarter_seq,
        ca.ca_state
    FROM call_center cc
    JOIN catalog_returns cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cc.cc_company = 2
      AND cc.cc_division_name = 'pri'
      AND d.d_year = 1916
      AND d.d_quarter_seq = 5
      AND cr.cr_return_amount > 1000.00
      AND ca.ca_state = 'CA'
),
aggregated AS (
    SELECT
        cc_call_center_id,
        d_year,
        d_quarter_seq,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_refunded_cash) AS avg_refunded_cash,
        COUNT(DISTINCT cr_order_number) AS num_orders,
        MIN(cr_return_amount) AS min_return_amount,
        MAX(cr_return_amount) AS max_return_amount
    FROM filtered
    GROUP BY
        cc_call_center_id,
        d_year,
        d_quarter_seq
),
high_returns AS (
    SELECT
        cc_call_center_id,
        d_year,
        d_quarter_seq,
        total_return_amount,
        avg_refunded_cash,
        num_orders,
        min_return_amount,
        max_return_amount
    FROM aggregated
    WHERE total_return_amount > 1000
),
very_high_returns AS (
    SELECT
        cc_call_center_id,
        d_year,
        d_quarter_seq,
        total_return_amount,
        avg_refunded_cash,
        num_orders,
        min_return_amount,
        max_return_amount
    FROM aggregated
    WHERE total_return_amount > 2000
),
combined AS (
    SELECT
        h.cc_call_center_id,
        h.d_year,
        h.d_quarter_seq,
        h.total_return_amount,
        h.avg_refunded_cash,
        h.num_orders,
        (SELECT AVG(total_return_amount) FROM aggregated) AS overall_avg_total_return,
        CASE
            WHEN EXISTS (SELECT 1 FROM aggregated a2 WHERE a2.total_return_amount > 10000)
            THEN 'YES'
            ELSE 'NO'
        END AS has_very_high_total
    FROM high_returns h
    EXCEPT
    SELECT
        v.cc_call_center_id,
        v.d_year,
        v.d_quarter_seq,
        v.total_return_amount,
        v.avg_refunded_cash,
        v.num_orders,
        (SELECT AVG(total_return_amount) FROM aggregated) AS overall_avg_total_return,
        CASE
            WHEN EXISTS (SELECT 1 FROM aggregated a2 WHERE a2.total_return_amount > 10000)
            THEN 'YES'
            ELSE 'NO'
        END AS has_very_high_total
    FROM very_high_returns v
)
SELECT
    cc_call_center_id,
    d_year,
    d_quarter_seq,
    total_return_amount,
    avg_refunded_cash,
    num_orders,
    overall_avg_total_return,
    has_very_high_total
FROM combined
ORDER BY total_return_amount DESC
LIMIT 100
