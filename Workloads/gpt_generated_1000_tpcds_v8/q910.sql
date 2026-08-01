WITH sales_customer AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_ship_date_sk,
    cs.cs_bill_customer_sk,
    cs.cs_quantity,
    cs.cs_ext_ship_cost,
    cs.cs_net_paid,
    cs.cs_ext_discount_amt,
    cs.cs_coupon_amt,
    cs.cs_net_profit,
    c.c_customer_sk,
    c.c_salutation,
    c.c_birth_year,
    d.d_date AS sold_date,
    d.d_year AS sold_year,
    d.d_dow AS sold_dow
  FROM catalog_sales cs
  FULL OUTER JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE
    c.c_salutation = 'Mr.'
    AND c.c_birth_year BETWEEN 1950 AND 1970
    AND cs.cs_coupon_amt < 500
    AND d.d_year = 2002
),
filtered AS (
  SELECT *
  FROM sales_customer sc
  WHERE EXISTS (
          SELECT 1
          FROM date_dim d_ship
          WHERE d_ship.d_date_sk = sc.cs_ship_date_sk
            AND d_ship.d_year = 2002
            AND d_ship.d_dow = 3
        )
    AND NOT EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_bill_customer_sk = sc.c_customer_sk
            AND cs2.cs_coupon_amt > 1000
        )
)
SELECT
  sc.c_salutation,
  sc.c_birth_year,
  sc.sold_year,
  metric,
  COUNT(*) AS sales_cnt,
  SUM(sc.cs_net_paid) AS total_net_paid,
  AVG(sc.cs_ext_discount_amt) AS avg_discount,
  MIN(sc.cs_net_profit) AS min_profit,
  MAX(sc.cs_coupon_amt) AS max_coupon
FROM filtered sc
CROSS JOIN LATERAL (
    SELECT ARRAY[ sc.cs_quantity, CAST(sc.cs_ext_ship_cost AS double) ] AS arr
) AS l(arr)
CROSS JOIN UNNEST(l.arr) AS u(metric)
GROUP BY
  sc.c_salutation,
  sc.c_birth_year,
  sc.sold_year,
  metric
ORDER BY total_net_paid DESC
OFFSET 0 LIMIT 100
