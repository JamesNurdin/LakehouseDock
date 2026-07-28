WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_cdemo_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        d.d_year,
        s.s_store_name,
        s.s_state,
        cd.cd_gender,
        cd.cd_marital_status
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq = 12
      AND s.s_state = 'CA'
      AND cd.cd_marital_status = 'M'
      AND ss.ss_quantity >= 80
      AND ss.ss_sales_price > 30.00
)
SELECT
    s_store_name,
    d_year,
    cd_gender,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_sales_price) AS avg_unit_price,
    COUNT(*) AS txn_count,
    MIN(ss_sales_price) AS min_unit_price,
    MAX(ss_sales_price) AS max_unit_price
FROM filtered_sales
GROUP BY s_store_name, d_year, cd_gender
HAVING SUM(ss_ext_sales_price) > 100000
   AND COUNT(*) >= 10
ORDER BY total_sales DESC
LIMIT 10
