WITH
  -- Full outer join between catalog_returns and store via date_dim
  full_joined AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_returned_date_sk,
      s.s_store_id,
      s.s_store_name,
      d.d_date
    FROM catalog_returns cr
      LEFT JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
      FULL OUTER JOIN (
        SELECT
          s.s_store_id,
          s.s_store_name,
          d2.d_date_sk,
          d2.d_date
        FROM store s
          JOIN date_dim d2 ON s.s_closed_date_sk = d2.d_date_sk
        WHERE s.s_store_id IN (
          SELECT cp_catalog_page_id
          FROM catalog_page
          WHERE cp_department = 'Electronics'
        )
      ) s ON cr.cr_returned_date_sk = s.d_date_sk
    WHERE cr.cr_return_quantity IN (
      SELECT DISTINCT cr3.cr_return_quantity
      FROM catalog_returns cr3
      WHERE cr3.cr_return_amount > 500.00
    )
  ),

  -- Customers with a correlated aggregate of their return amounts
  customer_returns AS (
    SELECT
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      (
        SELECT SUM(cr4.cr_return_amount)
        FROM catalog_returns cr4
        WHERE cr4.cr_returning_customer_sk = c.c_customer_sk
      ) AS total_return_amount
    FROM customer c
    WHERE c.c_birth_month = 5
  ),

  -- Store IDs that are active (i.e., not closed)
  active_store_ids AS (
    SELECT s_store_id FROM store
    EXCEPT
    SELECT s_store_id FROM store WHERE s_closed_date_sk IS NOT NULL
  )

SELECT *
FROM (
  SELECT
    fj.cr_order_number      AS order_num,
    fj.cr_return_amount     AS return_amt,
    fj.d_date               AS return_date,
    fj.s_store_id           AS store_id,
    fj.s_store_name         AS store_name,
    NULL                    AS customer_id,
    NULL                    AS total_return_amount
  FROM full_joined fj

  UNION ALL

  SELECT
    NULL                    AS order_num,
    cr.total_return_amount  AS return_amt,
    NULL                    AS return_date,
    NULL                    AS store_id,
    NULL                    AS store_name,
    cr.c_customer_id        AS customer_id,
    cr.total_return_amount  AS total_return_amount
  FROM customer_returns cr
) combined
WHERE store_id IN (SELECT s_store_id FROM active_store_ids)
ORDER BY return_amt DESC
LIMIT 100
