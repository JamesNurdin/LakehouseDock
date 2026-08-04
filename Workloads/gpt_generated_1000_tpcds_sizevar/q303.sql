/* Goal: Identify customers with high‑value morning store purchases who have not returned any items for a defective reason in the afternoon, and paginate the distinct customer IDs. */
SELECT c_customer_id
FROM (
    SELECT DISTINCT c.c_customer_id
    FROM store_sales ss
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_am_pm = 'AM'
      AND ss.ss_net_paid_inc_tax > 1000
      AND ss.ss_item_sk BETWEEN 100000 AND 200000
    EXCEPT
    SELECT DISTINCT c.c_customer_id
    FROM store_returns sr
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t
      ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_am_pm = 'PM'
      AND sr.sr_return_amt > 0
      AND r.r_reason_desc = 'Defective'
) AS result
ORDER BY c_customer_id
OFFSET 20
LIMIT 100
