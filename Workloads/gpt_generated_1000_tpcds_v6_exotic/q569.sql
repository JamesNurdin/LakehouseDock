WITH joined_data AS (
  SELECT
    d_cs.d_year AS year,
    d_cs.d_quarter_seq AS quarter_seq,
    i.i_brand AS brand,
    i.i_category AS category,
    cp.cp_department AS department,
    p.p_promo_name AS promo_name,
    p.p_discount_active AS discount_active,
    cs.cs_ext_sales_price AS catalog_sales_amount,
    ss.ss_ext_sales_price AS store_sales_amount,
    cs.cs_net_profit + ss.ss_net_profit AS total_profit,
    CASE
      WHEN p.p_discount_active = 'Y' THEN cs.cs_ext_sales_price + ss.ss_ext_sales_price
      ELSE 0
    END AS promo_sales
  FROM catalog_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN date_dim d_cs
    ON cs.cs_sold_date_sk = d_cs.d_date_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_cs.d_date_sk
  JOIN date_dim d_ss
    ON ss.ss_sold_date_sk = d_ss.d_date_sk
  WHERE
    d_cs.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND p.p_channel_demo = 'N'
    AND d_cs.d_fy_quarter_seq IN (4,5,6,7,8,9,10)
),
agg_data AS (
  SELECT
    year,
    quarter_seq,
    brand,
    category,
    department,
    promo_name,
    discount_active,
    SUM(catalog_sales_amount) AS sum_catalog_sales,
    SUM(store_sales_amount) AS sum_store_sales,
    SUM(total_profit) AS sum_total_profit,
    SUM(promo_sales) AS sum_promo_sales
  FROM joined_data
  GROUP BY
    year,
    quarter_seq,
    brand,
    category,
    department,
    promo_name,
    discount_active
  HAVING
    SUM(catalog_sales_amount) + SUM(store_sales_amount) > 10000
)
SELECT
  year,
  quarter_seq,
  brand,
  category,
  department,
  promo_name,
  discount_active,
  sum_catalog_sales,
  sum_store_sales,
  sum_total_profit,
  sum_promo_sales,
  (sum_catalog_sales + sum_store_sales) AS total_sales,
  RANK() OVER (ORDER BY (sum_catalog_sales + sum_store_sales) DESC) AS sales_rank,
  SUM(sum_catalog_sales + sum_store_sales) OVER (PARTITION BY year) AS yearly_total_sales
FROM agg_data
ORDER BY total_sales DESC
LIMIT 100
