WITH sales_agg AS (
   SELECT
       c.c_customer_sk,
       c.c_customer_id,
       c.c_email_address,
       d.d_year,
       i.i_item_sk,
       i.i_item_id,
       i.i_item_desc,
       i.i_brand,
       cs.cs_order_number,
       cs.cs_catalog_page_sk,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       COUNT(*) AS order_cnt,
       REGEXP_EXTRACT(i.i_item_desc, '(\\w+)', 1) AS first_word,
       CONCAT(i.i_item_id, '-', i.i_brand) AS product_code
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
     AND REGEXP_LIKE(i.i_item_desc, '.*[A-Z]{3}.*')
     AND p.p_channel_demo = 'N'
   GROUP BY
       c.c_customer_sk,
       c.c_customer_id,
       c.c_email_address,
       d.d_year,
       i.i_item_sk,
       i.i_item_id,
       i.i_item_desc,
       i.i_brand,
       cs.cs_order_number,
       cs.cs_catalog_page_sk
)

SELECT
    DISTINCT s.c_email_address,
    s.c_customer_id,
    s.d_year,
    s.product_code,
    s.first_word,
    s.total_sales,
    s.order_cnt,
    ROW_NUMBER() OVER (PARTITION BY s.d_year ORDER BY s.total_sales DESC) AS sales_rank
FROM sales_agg s
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs2
    JOIN catalog_page cp ON cs2.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs2.cs_order_number = s.cs_order_number
      AND cp.cp_description LIKE '%special%'
)
ORDER BY s.total_sales DESC
LIMIT 100
