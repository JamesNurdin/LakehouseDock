WITH
  store_cust AS (
    SELECT c.c_customer_id
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2020
  ),
  web_cust AS (
    SELECT c.c_customer_id
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2020
  ),
  promo_cust AS (
    SELECT DISTINCT c.c_customer_id
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2020
    UNION
    SELECT DISTINCT c.c_customer_id
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2020
  ),
  catalog_2021_cust AS (
    SELECT DISTINCT c.c_customer_id
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2021
  ),
  combined AS (
    SELECT c_id FROM (
      SELECT c_customer_id AS c_id FROM store_cust
      UNION
      SELECT c_customer_id AS c_id FROM web_cust
    )
    INTERSECT
    SELECT c_customer_id FROM promo_cust
    EXCEPT
    SELECT c_customer_id FROM catalog_2021_cust
  )
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  t.t_shift,
  dy.d_year
FROM combined comb
JOIN customer c ON c.c_customer_id = comb.c_id
CROSS JOIN (
  SELECT t_shift
  FROM time_dim
  WHERE t_shift = 'first'
  LIMIT 1
) t
CROSS JOIN (
  SELECT d_year
  FROM date_dim
  WHERE d_year = 2020
  LIMIT 1
) dy
WHERE EXISTS (
  SELECT 1
  FROM catalog_sales cs
  JOIN date_dim dcs ON cs.cs_sold_date_sk = dcs.d_date_sk
  WHERE cs.cs_bill_customer_sk = c.c_customer_sk
    AND dcs.d_year = 2020
)
ORDER BY c.c_customer_id
OFFSET 0 LIMIT 100
