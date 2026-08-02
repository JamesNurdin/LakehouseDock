WITH agg_sales AS (
    SELECT
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt,
        ARRAY_AGG(DISTINCT ss_item_sk) AS items_array,
        SUM(ss_ext_tax) AS total_tax,
        AVG(ss_ext_discount_amt) AS avg_discount
    FROM store_sales
    WHERE ss_ext_tax > 10
      AND ss_ext_list_price < 15000
      AND ss_coupon_amt < 3000
    GROUP BY ss_customer_sk
    HAVING SUM(ss_ext_sales_price) > 5000
)
SELECT DISTINCT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    c.c_birth_year,
    agg.total_sales,
    agg.sales_cnt,
    agg.total_tax,
    agg.avg_discount,
    t.item_sk,
    RANK() OVER (PARTITION BY c.c_birth_country ORDER BY agg.total_sales DESC) AS country_sales_rank,
    CASE
        WHEN agg.total_sales > 20000 THEN 'High'
        WHEN agg.total_sales > 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM agg_sales AS agg
JOIN customer AS c
    ON agg.ss_customer_sk = c.c_customer_sk
CROSS JOIN UNNEST(agg.items_array) AS t(item_sk)
WHERE c.c_birth_country IN ('JAPAN', 'MONACO', 'BHUTAN')
  AND c.c_birth_year BETWEEN 1950 AND 1970
  AND agg.total_sales > 10000
  AND NOT EXISTS (
        SELECT 1 FROM store_sales s2
        WHERE s2.ss_customer_sk = c.c_customer_sk
          AND s2.ss_coupon_amt > 2000
    )
ORDER BY agg.total_sales DESC
LIMIT 100
