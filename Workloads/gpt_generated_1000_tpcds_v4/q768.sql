WITH filtered_returns AS (
    SELECT
        sr_store_sk,
        sr_ticket_number,
        sr_return_amt,
        sr_return_quantity,
        sr_return_amt_inc_tax,
        sr_return_time_sk,
        sr_reversed_charge,
        sr_refunded_cash
    FROM store_returns
    WHERE sr_return_time_sk BETWEEN 30000 AND 40000
        AND sr_reversed_charge > 15.00
        AND sr_refunded_cash < 100.00
)
SELECT
    s.s_state,
    s.s_market_id,
    s.s_division_name,
    COUNT(DISTINCT fr.sr_ticket_number) AS distinct_tickets,
    SUM(fr.sr_return_amt) AS total_return_amount,
    AVG(fr.sr_return_quantity) AS avg_return_qty,
    MIN(fr.sr_return_amt_inc_tax) AS min_return_inc_tax,
    MAX(fr.sr_return_amt_inc_tax) AS max_return_inc_tax,
    SUM(CASE WHEN fr.sr_return_amt > 200 THEN 1 ELSE 0 END) AS high_value_returns
FROM filtered_returns fr
JOIN store s
    ON fr.sr_store_sk = s.s_store_sk
WHERE s.s_state = 'CA'
    AND s.s_market_id = 5
    AND s.s_company_name = 'Unknown'
GROUP BY s.s_state, s.s_market_id, s.s_division_name
HAVING SUM(fr.sr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
