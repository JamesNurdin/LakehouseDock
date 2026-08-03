WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_tax) AS total_tax,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM sampled_sales ss
    WHERE ss.ss_ext_tax >= 0
      AND ss.ss_ext_sales_price > 0
      AND ss.ss_promo_sk IN (7, 172, 378)
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
),
joined AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_item_sk,
        i.i_product_name,
        c.c_customer_sk,
        cd.cd_gender,
        ca.ca_state,
        t.t_hour,
        sa.total_sales,
        sa.total_tax,
        sa.sales_category,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY sa.total_sales DESC) AS rn
    FROM sales_agg sa
    JOIN store s ON sa.ss_store_sk = s.s_store_sk
    JOIN item i ON sa.ss_item_sk = i.i_item_sk
    JOIN store_sales ss2 ON ss2.ss_store_sk = s.s_store_sk AND ss2.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss2.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON ss2.ss_sold_time_sk = t.t_time_sk
    WHERE i.i_manufact_id IN (260, 52)
      AND ca.ca_country = 'United States'
      AND t.t_hour BETWEEN 9 AND 17
      AND s.s_company_name = 'Unknown'
)
SELECT
    j.s_store_name,
    j.i_product_name,
    j.total_sales,
    j.total_tax,
    j.sales_category,
    j.ca_state,
    j.cd_gender,
    j.t_hour
FROM joined j
WHERE j.rn <= 5
  AND (j.s_store_sk, j.i_item_sk) IN (
        SELECT ss_store_sk, ss_item_sk FROM store_sales
        EXCEPT
        SELECT ss_store_sk, ss_item_sk FROM store_sales WHERE ss_promo_sk = 1061
    )
ORDER BY j.total_sales DESC
LIMIT 100
