WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk,
        MIN(cs.cs_call_center_sk) AS call_center_sk,
        MIN(cs.cs_catalog_page_sk) AS catalog_page_sk,
        MIN(cs.cs_item_sk) AS item_sk,
        MIN(cs.cs_promo_sk) AS promo_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM tpcds.catalog_sales cs
    TABLESAMPLE BERNOULLI (10)
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
      AND cs.cs_quantity > (
          SELECT MAX(cs2.cs_quantity)
          FROM tpcds.catalog_sales cs2
          WHERE cs2.cs_quantity > 0
      )
    GROUP BY cs.cs_bill_customer_sk
)
SELECT
    sa.sales_category,
    COUNT(DISTINCT c.c_customer_id) AS customer_cnt,
    AVG(sa.total_sales) AS avg_total_sales
FROM sales_agg sa
JOIN tpcds.customer c
    ON sa.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics d
    ON c.c_current_cdemo_sk = d.cd_demo_sk
JOIN tpcds.call_center cc
    ON sa.call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON sa.catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.item i
    ON sa.item_sk = i.i_item_sk
JOIN tpcds.promotion p
    ON sa.promo_sk = p.p_promo_sk
JOIN tpcds.web_page wp
    ON c.c_customer_sk = wp.wp_customer_sk
WHERE cc.cc_state = 'CA'
  AND i.i_units = 'Carton'
  AND c.c_birth_country = 'MEXICO'
  AND wp.wp_url LIKE 'http%'
GROUP BY sa.sales_category
HAVING AVG(sa.total_sales) > (
    SELECT AVG(total_sales)
    FROM sales_agg
)
ORDER BY avg_total_sales DESC
LIMIT 100
