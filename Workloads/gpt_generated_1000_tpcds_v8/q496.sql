WITH first_part AS (
  SELECT
    d.d_year,
    s.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
    inv_agg.total_qty
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN store s ON s.s_closed_date_sk = d.d_date_sk
  LEFT JOIN LATERAL (
    SELECT SUM(i.inv_quantity_on_hand) AS total_qty
    FROM inventory i
    WHERE i.inv_date_sk = d.d_date_sk
      AND i.inv_item_sk = cs.cs_item_sk
  ) inv_agg ON TRUE
  WHERE cs.cs_bill_cdemo_sk IN (
        SELECT cd_demo_sk
        FROM customer_demographics
        WHERE cd_marital_status = 'M'
      )
    AND d.d_year = 2001
  GROUP BY d.d_year, s.s_state, inv_agg.total_qty
),
second_part AS (
  SELECT
    d.d_year,
    s.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
    inv_agg.total_qty
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
  JOIN store s ON s.s_closed_date_sk = d.d_date_sk
  LEFT JOIN LATERAL (
    SELECT SUM(i.inv_quantity_on_hand) AS total_qty
    FROM inventory i
    WHERE i.inv_date_sk = d.d_date_sk
      AND i.inv_item_sk = cs.cs_item_sk
  ) inv_agg ON TRUE
  WHERE cs.cs_bill_cdemo_sk IN (
        SELECT cd_demo_sk
        FROM customer_demographics
        WHERE cd_education_status = 'College'
      )
    AND d.d_year = 2002
  GROUP BY d.d_year, s.s_state, inv_agg.total_qty
)
SELECT *
FROM first_part
UNION
SELECT *
FROM second_part
ORDER BY d_year DESC, distinct_orders DESC
LIMIT 100
