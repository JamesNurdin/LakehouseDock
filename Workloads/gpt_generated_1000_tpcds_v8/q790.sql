WITH base AS (
  SELECT
    sr.sr_customer_sk,
    cd.cd_gender,
    r.r_reason_desc,
    t.t_shift,
    sr.sr_return_amt,
    sr.sr_fee,
    sr.sr_return_quantity,
    sr.sr_reason_sk
  FROM store_returns sr
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  WHERE r.r_reason_id = 'AAAAAAAAIAAAAAAA'
    AND t.t_shift = 'first'
    AND cd.cd_gender = 'M'
    AND sr.sr_return_quantity > (
        SELECT AVG(sr2.sr_return_quantity)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = sr.sr_customer_sk
    )
    AND sr.sr_reason_sk NOT IN (
        SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%duplicate%'
    )
),
second AS (
  SELECT
    sr.sr_customer_sk,
    cd.cd_gender,
    r.r_reason_desc,
    t.t_shift,
    sr.sr_return_amt,
    sr.sr_fee,
    sr.sr_return_quantity,
    sr.sr_reason_sk
  FROM store_returns sr
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  WHERE r.r_reason_id = 'AAAAAAADBAAAAAA'
    AND t.t_shift = 'second'
    AND cd.cd_gender = 'F'
    AND sr.sr_return_quantity > (
        SELECT AVG(sr2.sr_return_quantity)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = sr.sr_customer_sk
    )
    AND sr.sr_reason_sk NOT IN (
        SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%duplicate%'
    )
),
unioned AS (
  SELECT * FROM base
  UNION DISTINCT
  SELECT * FROM second
),
intersected_customers AS (
  SELECT sr_customer_sk FROM store_returns WHERE sr_return_tax > 20
  INTERSECT
  SELECT sr_customer_sk FROM store_returns WHERE sr_return_ship_cost > 50
)
SELECT
  u.cd_gender,
  u.r_reason_desc,
  u.t_shift,
  u.sr_customer_sk,
  COUNT(*) AS return_records,
  SUM(u.sr_return_amt) AS total_return_amt,
  AVG(u.sr_fee) AS avg_fee,
  MIN(u.sr_return_quantity) AS min_quantity,
  MAX(u.sr_return_quantity) AS max_quantity,
  (
    SELECT SUM(sr3.sr_return_amt)
    FROM store_returns sr3
    WHERE sr3.sr_customer_sk = u.sr_customer_sk
  ) AS customer_total_return_amt
FROM unioned u
WHERE u.sr_customer_sk IN (SELECT sr_customer_sk FROM intersected_customers)
GROUP BY u.cd_gender, u.r_reason_desc, u.t_shift, u.sr_customer_sk
HAVING SUM(u.sr_return_amt) > 1000
ORDER BY total_return_amt DESC
OFFSET 10 ROWS
LIMIT 100
