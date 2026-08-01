WITH
    -- Fact table (store_returns) right‑outer‑joined to the store dimension so every store is kept
    stores_returns AS (
        SELECT
            s.s_store_sk,
            s.s_store_name,
            COUNT(sr.sr_ticket_number)                           AS total_returns,
            COALESCE(SUM(sr.sr_return_amt), 0)                   AS total_return_amount,
            SUM(CASE WHEN sr.sr_reason_sk IN (
                    SELECT r.r_reason_sk
                    FROM reason r
                    WHERE regexp_like(r.r_reason_desc, '^Did not.*')
                      AND r.r_reason_desc LIKE '%color%'
                ) THEN 1 ELSE 0 END)                           AS filtered_reason_returns
        FROM store_returns sr
        RIGHT OUTER JOIN store s
            ON sr.sr_store_sk = s.s_store_sk
        GROUP BY s.s_store_sk, s.s_store_name
    ),
    -- Scalar subquery returning a single value (maximum return amount)
    max_return AS (
        SELECT MAX(sr_return_amt) AS max_amt FROM store_returns
    ),
    -- Customers that have never returned an item > 100 and whose birth country is all‑caps (using regexp_extract)
    eligible_customers AS (
        SELECT
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            c.c_birth_country
        FROM customer c
        WHERE c.c_customer_sk NOT IN (
                  SELECT sr_customer_sk FROM store_returns WHERE sr_return_amt > 100
              )
          AND regexp_extract(c.c_birth_country, '^[A-Z]+') = c.c_birth_country
    ),
    -- Intersection of store keys that appear in store_returns and customer keys that appear in web_returns
    intersect_keys AS (
        SELECT sr_store_sk AS key_id FROM store_returns WHERE sr_return_quantity > 0
        INTERSECT
        SELECT wr_returning_customer_sk FROM web_returns WHERE wr_return_quantity > 0
    )
SELECT
    sr.s_store_name,
    sr.total_returns,
    sr.total_return_amount,
    ec.c_first_name || ' ' || ec.c_last_name                                 AS customer_full_name,
    (
        SELECT COUNT(*)
        FROM eligible_customers ec2
        WHERE ec2.c_birth_country = ec.c_birth_country
    )                                                                        AS same_country_customer_count,
    (SELECT max_amt FROM max_return)                                         AS max_return_amount
FROM stores_returns sr
JOIN eligible_customers ec
    ON ec.c_customer_sk = (
        SELECT MIN(sr_customer_sk)
        FROM store_returns
        WHERE sr_store_sk = sr.s_store_sk
    )
WHERE sr.filtered_reason_returns > 0
  AND sr.s_store_sk IN (SELECT key_id FROM intersect_keys)
GROUP BY
    sr.s_store_name,
    sr.total_returns,
    sr.total_return_amount,
    ec.c_first_name,
    ec.c_last_name,
    ec.c_birth_country
HAVING sr.total_return_amount > (SELECT max_amt FROM max_return) / 2
ORDER BY sr.total_return_amount DESC
LIMIT 100
