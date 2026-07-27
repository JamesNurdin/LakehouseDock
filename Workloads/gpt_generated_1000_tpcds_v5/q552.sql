WITH filtered_returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_reason_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_returning_customer_sk
    FROM web_returns wr
    WHERE wr.wr_return_amt > 100.00
      AND wr.wr_return_quantity >= 1
      AND wr.wr_net_loss > 0
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2453000
      AND wr.wr_reason_sk IN (
          SELECT r2.r_reason_sk
          FROM reason r2
          WHERE r2.r_reason_desc LIKE '%damaged%'
      )
)
SELECT
    cr.c_customer_id,
    cr.c_salutation,
    r.r_reason_desc,
    td.t_sub_shift,
    fr.wr_return_amt,
    fr.wr_net_loss,
    AVG(fr.wr_return_amt) OVER (PARTITION BY r.r_reason_id) AS avg_amt_by_reason,
    RANK() OVER (PARTITION BY td.t_sub_shift ORDER BY fr.wr_return_amt DESC) AS rank_in_shift,
    CASE
        WHEN fr.wr_return_amt > (
            SELECT AVG(wr3.wr_return_amt)
            FROM web_returns wr3
            WHERE wr3.wr_reason_sk = r.r_reason_sk
        ) THEN 'High'
        ELSE 'Normal'
    END AS amt_category
FROM filtered_returns fr
JOIN time_dim td
    ON fr.wr_returned_time_sk = td.t_time_sk
JOIN reason r
    ON fr.wr_reason_sk = r.r_reason_sk
JOIN customer cr
    ON fr.wr_refunded_customer_sk = cr.c_customer_sk
JOIN customer cr_ret
    ON fr.wr_returning_customer_sk = cr_ret.c_customer_sk
WHERE cr.c_salutation IN ('Mr.', 'Ms.')
  AND cr.c_birth_day BETWEEN 1 AND 15
  AND td.t_sub_shift = 'morning'
ORDER BY rank_in_shift, cr.c_customer_id
LIMIT 100
