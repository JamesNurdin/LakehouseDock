WITH store_sales_agg AS (
  SELECT
    c.c_customer_id,
    SUM(ss.ss_net_paid) AS total_net_paid,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    (SELECT COUNT(DISTINCT i2.i_color)
     FROM item i2
     WHERE i2.i_brand = i.i_brand) AS distinct_colors_per_brand
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2001
    AND i.i_color = 'purple'
    AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ss.ss_promo_sk
          AND p.p_discount_active = 'Y'
    )
  GROUP BY c.c_customer_id, i.i_brand
),

catalog_sales_agg AS (
  SELECT
    c.c_customer_id,
    SUM(cs.cs_net_paid) AS total_net_paid,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    (SELECT COUNT(DISTINCT i2.i_color)
     FROM item i2
     WHERE i2.i_brand = i.i_brand) AS distinct_colors_per_brand
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2001
    AND i.i_color = 'purple'
    AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = cs.cs_promo_sk
          AND p.p_discount_active = 'Y'
    )
  GROUP BY c.c_customer_id, i.i_brand
)

SELECT *
FROM (
  SELECT c_customer_id, total_net_paid, profit_flag, distinct_colors_per_brand
  FROM store_sales_agg
  UNION ALL
  SELECT c_customer_id, total_net_paid, profit_flag, distinct_colors_per_brand
  FROM catalog_sales_agg
) combined
ORDER BY total_net_paid DESC
LIMIT 100
