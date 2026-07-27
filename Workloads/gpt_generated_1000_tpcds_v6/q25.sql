WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_amt_inc_tax,
        d.d_year,
        d.d_fy_quarter_seq,
        d.d_current_week
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002                                 -- filter 1
      AND d.d_fy_quarter_seq = 10                         -- filter 2
      AND d.d_current_week = 'N'                          -- filter 3
      AND sr.sr_return_quantity > 1                       -- filter 4
      AND sr.sr_reason_sk IN (34, 38)                     -- filter 5
)
SELECT
    cc.cc_division_name,
    p.p_promo_name,
    fr.d_year,
    fr.d_fy_quarter_seq,
    COUNT(DISTINCT fr.sr_ticket_number) AS distinct_tickets,
    SUM(fr.sr_return_amt) AS total_return_amt,
    AVG(fr.sr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
    SUM(CASE WHEN p.p_channel_tv = 'Y' THEN fr.sr_return_amt ELSE 0 END) AS tv_promo_return_amt,
    MIN(fr.sr_return_amt) AS min_return_amt,
    MAX(fr.sr_return_amt) AS max_return_amt
FROM filtered_returns fr
JOIN call_center cc
  ON cc.cc_closed_date_sk = fr.sr_returned_date_sk
JOIN promotion p
  ON p.p_start_date_sk = fr.sr_returned_date_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_start_date_sk = fr.sr_returned_date_sk
      AND p2.p_discount_active = 'Y'
)
GROUP BY
    cc.cc_division_name,
    p.p_promo_name,
    fr.d_year,
    fr.d_fy_quarter_seq
ORDER BY total_return_amt DESC
LIMIT 100
