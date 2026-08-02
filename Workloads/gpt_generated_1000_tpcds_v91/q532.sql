WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        d.d_year,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        cd.cd_dep_employed_count,
        (SELECT ca.ca_state FROM customer_address ca WHERE ca.ca_address_sk = ss.ss_addr_sk) AS ca_state,
        (SELECT ca.ca_city FROM customer_address ca WHERE ca.ca_address_sk = ss.ss_addr_sk) AS ca_city
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2002
      AND d.d_week_seq IN (7, 13, 14)
      AND cd.cd_purchase_estimate >= 4000
      AND cd.cd_dep_employed_count <= 5
      AND ss.ss_quantity > 1
      AND ss.ss_ext_sales_price > 100
      AND EXISTS (
          SELECT 1
          FROM customer_address ca2
          WHERE ca2.ca_address_sk = ss.ss_addr_sk
            AND ca2.ca_state = 'TX'
            AND ca2.ca_country = 'United States'
      )
)
SELECT
    ca_state,
    d_year,
    cd_gender,
    COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_ext_sales_price) AS avg_sales,
    MIN(ss_ext_sales_price) AS min_sales,
    MAX(ss_ext_sales_price) AS max_sales,
    SUM(ss_net_profit) AS total_profit,
    CASE
        WHEN SUM(ss_net_profit) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_flag,
    (SELECT SUM(ss2.ss_ext_sales_price)
       FROM store_sales ss2
       JOIN customer_address ca2
         ON ss2.ss_addr_sk = ca2.ca_address_sk
      WHERE ca2.ca_state = base.ca_state) AS state_total_sales
FROM base
GROUP BY ROLLUP (ca_state, d_year, cd_gender)
ORDER BY
    ca_state ASC NULLS FIRST,
    d_year ASC NULLS FIRST,
    cd_gender ASC NULLS FIRST
