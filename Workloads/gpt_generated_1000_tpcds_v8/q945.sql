WITH
  store_agg AS (
    SELECT
      d.d_date,
      sr.sr_customer_sk,
      SUM(sr.sr_return_amt) AS store_return_total,
      COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date, sr.sr_customer_sk
  ),
  web_agg AS (
    SELECT
      d.d_date,
      wr.wr_refunded_customer_sk AS customer_sk,
      SUM(wr.wr_return_amt) AS web_return_total,
      COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date, wr.wr_refunded_customer_sk
  ),
  full_join AS (
    SELECT
      COALESCE(sa.d_date, wa.d_date) AS return_date,
      COALESCE(sa.sr_customer_sk, wa.customer_sk) AS customer_sk,
      sa.store_return_total,
      wa.web_return_total
    FROM store_agg sa
    FULL OUTER JOIN web_agg wa
      ON sa.d_date = wa.d_date
     AND sa.sr_customer_sk = wa.customer_sk
  ),
  customer_set AS (
    SELECT DISTINCT fj.customer_sk
    FROM full_join fj
    WHERE fj.store_return_total IS NOT NULL
      AND fj.web_return_total IS NOT NULL
  ),
  income_bands AS (
    SELECT DISTINCT hd_income_band_sk
    FROM household_demographics
    WHERE hd_income_band_sk IS NOT NULL
  ),
  high_return_customers AS (
    SELECT fj.customer_sk
    FROM full_join fj
    WHERE (fj.store_return_total + COALESCE(fj.web_return_total, 0)) > (
      SELECT AVG(sr_amount)
      FROM (
        SELECT SUM(sr.sr_return_amt) AS sr_amount
        FROM store_returns sr
        GROUP BY sr.sr_customer_sk
      ) t
    )
  ),
  intersect_customers AS (
    SELECT cs.customer_sk
    FROM customer_set cs
    INTERSECT
    SELECT hrc.customer_sk FROM high_return_customers hrc
  ),
  cross_joined AS (
    SELECT ib.hd_income_band_sk, ic.customer_sk
    FROM income_bands ib
    CROSS JOIN intersect_customers ic
  ),
  final_result AS (
    SELECT
      cj.hd_income_band_sk,
      cj.customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_city,
      ca.ca_state,
      fj.store_return_total,
      fj.web_return_total,
      (
        SELECT COALESCE(SUM(sr.sr_return_amt), 0) + COALESCE(SUM(wr.wr_return_amt), 0)
        FROM store_returns sr
        JOIN web_returns wr ON sr.sr_customer_sk = wr.wr_refunded_customer_sk
        WHERE sr.sr_customer_sk = cj.customer_sk
      ) AS total_return_amount,
      lst.recent_store_returns
    FROM cross_joined cj
    LEFT JOIN customer c ON c.c_customer_sk = cj.customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN full_join fj ON fj.customer_sk = cj.customer_sk
    LEFT JOIN LATERAL (
      SELECT COUNT(*) AS recent_store_returns
      FROM store_returns sr2
      WHERE sr2.sr_customer_sk = cj.customer_sk
        AND sr2.sr_returned_date_sk IN (
          SELECT d_date_sk
          FROM date_dim
          WHERE d_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
        )
    ) lst ON true
    WHERE fj.store_return_total IS NOT NULL OR fj.web_return_total IS NOT NULL
  )
SELECT DISTINCT
       fr.hd_income_band_sk,
       fr.customer_sk,
       fr.c_first_name,
       fr.c_last_name,
       fr.ca_city,
       fr.ca_state,
       fr.store_return_total,
       fr.web_return_total,
       fr.total_return_amount
FROM final_result fr
WHERE fr.total_return_amount > 1000
ORDER BY fr.total_return_amount DESC
LIMIT 100
