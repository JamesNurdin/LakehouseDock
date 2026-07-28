/*
  Goal: Identify distinct customer addresses that experienced high-value returns (>= $100) in the year 2001, either via store returns or web returns, and where the returned item was under an active promotion at the time of return.
*/
SELECT DISTINCT
  ca.ca_address_id,
  sr.sr_return_amt,
  d.d_year
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE sr.sr_return_amt >= 100
  AND d.d_year = 2001
  AND EXISTS (
        SELECT 1
        FROM promotion p
        JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
        JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk
        WHERE p.p_item_sk = i.i_item_sk
          AND d.d_date BETWEEN d_start.d_date AND d_end.d_date
          AND p.p_discount_active = 'Y'
      )

UNION ALL

SELECT DISTINCT
  ca.ca_address_id,
  wr.wr_return_amt,
  d.d_year
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE wr.wr_return_amt >= 100
  AND d.d_year = 2001
  AND EXISTS (
        SELECT 1
        FROM promotion p
        JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
        JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk
        WHERE p.p_item_sk = i.i_item_sk
          AND d.d_date BETWEEN d_start.d_date AND d_end.d_date
          AND p.p_discount_active = 'Y'
      )

ORDER BY ca_address_id, d_year DESC
LIMIT 100
