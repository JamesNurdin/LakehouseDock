/*
  Goal: Identify customers who made substantial purchases both in physical store sales and in catalog sales during the year 2002, and report each such customer's ID together with their store‑sales total and the current maximum price of a specific brand (BrandX). The query demonstrates:
  - A FULL OUTER JOIN between `store_sales` and `store` (keeping unmatched rows).
  - Sampling of both source tables with `TABLESAMPLE BERNOULLI`.
  - Expansion of an on‑the‑fly array using `UNNEST`.
  - An `EXISTS` correlated subquery.
  - A scalar subquery in the final SELECT.
  - An `INTERSECT` set operation to keep only customers present in both spending sets.
  - Final ordering of the result set.
*/
WITH store_spending AS (
    SELECT
        c.c_customer_id AS customer_id,
        SUM(u.qty * u.price) AS total_spent
    FROM (
        SELECT * FROM store_sales TABLESAMPLE BERNOULLI (5)
    ) ss
    FULL OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    CROSS JOIN UNNEST(
        ARRAY[ss.ss_quantity],
        ARRAY[ss.ss_sales_price]
    ) AS u(qty, price)
    WHERE d.d_year = 2002
    GROUP BY c.c_customer_id
    HAVING SUM(u.qty * u.price) > 1000
),
catalog_spending AS (
    SELECT
        c.c_customer_id AS customer_id,
        SUM(cs.cs_quantity * cs.cs_sales_price) AS total_spent
    FROM (
        SELECT * FROM catalog_sales TABLESAMPLE BERNOULLI (5)
    ) cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_ext_tax > 5
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd
          WHERE hd.hd_demo_sk = cs.cs_bill_hdemo_sk
            AND hd.hd_vehicle_count > 1
      )
    GROUP BY c.c_customer_id
    HAVING SUM(cs.cs_quantity * cs.cs_sales_price) > 500
)
SELECT
    intersected.customer_id,
    ss.total_spent AS store_total_spent,
    cs.total_spent AS catalog_total_spent,
    (
        SELECT MAX(i_current_price)
        FROM item
        WHERE i_brand = 'BrandX'
    ) AS max_brandx_price
FROM (
    SELECT customer_id FROM store_spending
    INTERSECT
    SELECT customer_id FROM catalog_spending
) intersected
LEFT JOIN store_spending ss
    ON intersected.customer_id = ss.customer_id
LEFT JOIN catalog_spending cs
    ON intersected.customer_id = cs.customer_id
ORDER BY intersected.customer_id
LIMIT 100
