WITH max_amount AS (
    SELECT MAX(cr_return_amount) AS max_amt
    FROM tpcds.catalog_returns
)

SELECT
    COALESCE(w.w_state, 'ALL') AS state,
    COALESCE(w.w_city, 'ALL') AS city,
    COALESCE(w.w_street_type, 'ALL') AS street_type,
    lt.total_warehouse_return_amount,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount
FROM tpcds.catalog_returns cr
JOIN tpcds.warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
CROSS JOIN LATERAL (
    SELECT SUM(cr2.cr_return_amount) AS total_warehouse_return_amount
    FROM tpcds.catalog_returns cr2
    WHERE cr2.cr_warehouse_sk = cr.cr_warehouse_sk
) lt
WHERE cr.cr_return_quantity > 1
  AND cr.cr_return_amount BETWEEN 10 AND 500
  AND w.w_state IN ('CA', 'TX', 'NY')
  AND w.w_street_type = 'Ave'
  AND cr.cr_fee < 20
  AND cr.cr_return_ship_cost > 5
  AND cr.cr_return_amount > (SELECT max_amt FROM max_amount)
GROUP BY CUBE(w.w_state, w.w_city, w.w_street_type, lt.total_warehouse_return_amount)

UNION DISTINCT

SELECT
    COALESCE(w.w_state, 'ALL') AS state,
    COALESCE(w.w_city, 'ALL') AS city,
    COALESCE(w.w_street_type, 'ALL') AS street_type,
    lt.total_warehouse_return_amount,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount
FROM tpcds.catalog_returns cr
JOIN tpcds.warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
CROSS JOIN LATERAL (
    SELECT SUM(cr2.cr_return_amount) AS total_warehouse_return_amount
    FROM tpcds.catalog_returns cr2
    WHERE cr2.cr_warehouse_sk = cr.cr_warehouse_sk
) lt
WHERE EXISTS (
        SELECT 1
        FROM tpcds.catalog_returns cr3
        WHERE cr3.cr_refunded_addr_sk = cr.cr_refunded_addr_sk
          AND cr3.cr_reversed_charge > 1000
      )
  AND w.w_city = 'Washington'
  AND cr.cr_store_credit BETWEEN 5 AND 10
  AND w.w_street_number = '305'
  AND cr.cr_return_tax < 5
GROUP BY CUBE(w.w_state, w.w_city, w.w_street_type, lt.total_warehouse_return_amount)

ORDER BY total_return_amount DESC
LIMIT 100
