WITH sales_enriched AS (
   SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      d.d_year,
      i.i_category,
      i.i_brand,
      i.i_brand_id,
      c.c_customer_id,
      c.c_customer_sk,
      c.c_birth_month,
      p.p_promo_name,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_ext_sales_price * 0.9 ELSE ss.ss_ext_sales_price END AS adjusted_sales,
      wr.wr_return_quantity,
      wp.wp_autogen_flag,
      ws.web_name
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN web_returns wr ON wr.wr_item_sk = ss.ss_item_sk AND wr.wr_returned_date_sk = ss.ss_sold_date_sk
   LEFT JOIN web_page wp ON wp.wp_customer_sk = ss.ss_customer_sk AND wp.wp_creation_date_sk = ss.ss_sold_date_sk
   LEFT JOIN web_site ws ON ws.web_open_date_sk = ss.ss_sold_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND i.i_brand_id IN (101, 102, 103)
     AND c.c_birth_month BETWEEN 4 AND 8
     AND (wp.wp_autogen_flag = 'Y' OR wp.wp_autogen_flag IS NULL)
)
SELECT
   se.i_category,
   se.i_brand,
   SUM(se.adjusted_sales) AS total_adj_sales,
   COUNT(*) AS sales_cnt,
   CASE WHEN SUM(se.adjusted_sales) > 50000 THEN 'HIGH' ELSE 'LOW' END AS sales_level,
   ROW_NUMBER() OVER (PARTITION BY se.i_category ORDER BY SUM(se.adjusted_sales) DESC) AS category_rank
FROM sales_enriched se
WHERE EXISTS (
    SELECT 1
    FROM call_center cc
    JOIN date_dim dcc ON cc.cc_closed_date_sk = dcc.d_date_sk
    WHERE dcc.d_date_sk = se.ss_sold_date_sk
      AND cc.cc_state = 'CA'
)
GROUP BY se.i_category, se.i_brand
HAVING SUM(se.adjusted_sales) > 50000
ORDER BY total_adj_sales DESC
LIMIT 100
