WITH
  store_sales_agg AS (
    SELECT
      d.d_year AS year,
      'store' AS source,
      s.s_store_name AS entity_name,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
      JOIN date_dim d       ON ss.ss_sold_date_sk = d.d_date_sk
      JOIN store s          ON ss.ss_store_sk = s.s_store_sk
      JOIN item i           ON ss.ss_item_sk = i.i_item_sk
      JOIN promotion p      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, '^[A-Z]{3}')
      AND p.p_promo_name LIKE '%Discount%'
    GROUP BY d.d_year, s.s_store_name
  ),
  catalog_sales_agg AS (
    SELECT
      d.d_year AS year,
      'catalog' AS source,
      concat(c.c_last_name, ', ', c.c_first_name) AS entity_name,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
      JOIN date_dim d          ON cs.cs_sold_date_sk = d.d_date_sk
      JOIN item i              ON cs.cs_item_sk = i.i_item_sk
      JOIN promotion p         ON cs.cs_promo_sk = p.p_promo_sk
      JOIN customer c          ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE regexp_extract(i.i_item_desc, '(\\d{4})', 1) = '2020'
      AND c.c_email_address LIKE '%@example.com'
      AND regexp_like(p.p_promo_name, '(?i)summer')
    GROUP BY d.d_year, c.c_last_name, c.c_first_name
  ),
  unioned AS (
    SELECT year, source, entity_name, total_sales, total_profit FROM store_sales_agg
    UNION
    SELECT year, source, entity_name, total_sales, total_profit FROM catalog_sales_agg
  )
SELECT
  year,
  source,
  entity_name,
  total_sales,
  total_profit,
  row_number() OVER (ORDER BY year DESC, total_sales DESC) AS rn
FROM unioned
ORDER BY rn
