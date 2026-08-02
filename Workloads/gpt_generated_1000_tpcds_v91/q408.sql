/*
Goal: Compare net loss from store returns and catalog returns per customer, include each customer's total catalog loss, filter to business hours (9‑17) and households with more than 3 dependents, and list the top 100 records by loss.
*/
WITH
store_ret AS (
    SELECT
        s.s_store_id AS store_id,
        c.c_customer_id AS customer_id,
        SUM(sr.sr_net_loss) AS total_store_loss,
        (
            SELECT SUM(cr2.cr_net_loss)
            FROM catalog_returns cr2
            WHERE cr2.cr_returning_customer_sk = c.c_customer_sk
        ) AS total_customer_catalog_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd
          WHERE hd.hd_demo_sk = sr.sr_hdemo_sk
            AND hd.hd_dep_count > 3
      )
    GROUP BY s.s_store_id, c.c_customer_id, c.c_customer_sk
),
catalog_ret AS (
    SELECT
        CAST('Catalog' AS varchar) AS store_id,
        c.c_customer_id AS customer_id,
        SUM(cr.cr_net_loss) AS total_store_loss,
        (
            SELECT SUM(cr2.cr_net_loss)
            FROM catalog_returns cr2
            WHERE cr2.cr_returning_customer_sk = c.c_customer_sk
        ) AS total_customer_catalog_loss
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND cr.cr_returning_hdemo_sk IN (
          SELECT hd.hd_demo_sk
          FROM household_demographics hd
          WHERE hd.hd_income_band_sk = 9
      )
    GROUP BY c.c_customer_id, c.c_customer_sk
)
SELECT *
FROM store_ret
UNION ALL
SELECT *
FROM catalog_ret
ORDER BY total_store_loss DESC
LIMIT 100
