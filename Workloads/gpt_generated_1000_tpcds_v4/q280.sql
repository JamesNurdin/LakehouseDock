WITH high_fee_returns AS (
    SELECT
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_store_sk,
        sr_return_amt,
        sr_return_tax,
        sr_fee,
        sr_ticket_number
    FROM store_returns
    WHERE sr_fee > 50.00
      AND sr_return_tax BETWEEN 10.00 AND 80.00
)
SELECT
    s.s_store_name,
    s.s_state,
    i.i_class,
    d.d_date,
    t.t_hour,
    SUM(hfr.sr_return_amt) AS total_return_amount,
    AVG(hfr.sr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT hfr.sr_ticket_number) AS distinct_tickets,
    CASE
        WHEN SUM(hfr.sr_return_amt) > 1000 THEN 'High'
        ELSE 'Low'
    END AS return_category
FROM high_fee_returns hfr
JOIN date_dim d
    ON hfr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON hfr.sr_return_time_sk = t.t_time_sk
JOIN item i
    ON hfr.sr_item_sk = i.i_item_sk
JOIN customer c
    ON hfr.sr_customer_sk = c.c_customer_sk
JOIN store s
    ON hfr.sr_store_sk = s.s_store_sk
WHERE d.d_year = 2001
  AND d.d_date = DATE '2001-07-15'
  AND t.t_hour BETWEEN 9 AND 17
  AND i.i_class = 'furniture'
  AND s.s_state = 'CA'
  AND c.c_preferred_cust_flag = 'Y'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND sr2.sr_return_amt > 500
        LIMIT 1
    )
GROUP BY
    s.s_store_name,
    s.s_state,
    i.i_class,
    d.d_date,
    t.t_hour
ORDER BY total_return_amount DESC
LIMIT 100
