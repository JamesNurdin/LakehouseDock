WITH high_value_customers AS (
    SELECT DISTINCT cr.cr_refunded_customer_sk AS c_customer_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 500
)
SELECT u.c_customer_id,
       u.r_reason_desc,
       u.return_amount,
       u.return_level,
       u.total_customer_return
FROM (
    SELECT c.c_customer_id,
           r.r_reason_desc,
           cr.cr_return_amount AS return_amount,
           CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Normal' END AS return_level,
           (
               SELECT SUM(cr2.cr_return_amount)
               FROM catalog_returns cr2
               WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
           ) AS total_customer_return
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM high_value_customers)
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_customer_sk = c.c_customer_sk
      )

    UNION ALL

    SELECT c.c_customer_id,
           r.r_reason_desc,
           wr.wr_return_amt AS return_amount,
           CASE WHEN wr.wr_return_amt > 1000 THEN 'High' ELSE 'Normal' END AS return_level,
           (
               SELECT SUM(wr2.wr_return_amt)
               FROM web_returns wr2
               WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
           ) AS total_customer_return
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM high_value_customers)
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_customer_sk = c.c_customer_sk
      )
) AS u
ORDER BY u.total_customer_return DESC
LIMIT 100
