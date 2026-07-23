WITH sales_agg AS (
    SELECT
        ss_item_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS trans_cnt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2455000
      AND ss_list_price > 30
      AND ss_quantity >= 2
      AND ss_ext_discount_amt < 500
    GROUP BY ss_item_sk, ss_customer_sk, ss_cdemo_sk
)
SELECT
    i.i_brand,
    i.i_category,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    s.total_sales,
    s.total_profit,
    s.trans_cnt,
    AVG(s.total_profit) OVER (PARTITION BY i.i_brand) AS avg_brand_profit,
    ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY s.total_sales DESC) AS brand_sales_rank
FROM sales_agg s
JOIN item i
    ON s.ss_item_sk = i.i_item_sk
JOIN customer c
    ON s.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON s.ss_cdemo_sk = cd.cd_demo_sk
WHERE i.i_current_price BETWEEN 20 AND 200
  AND c.c_preferred_cust_flag = 'Y'
  AND cd.cd_gender = 'M'
  AND cd.cd_dep_employed_count >= 1
ORDER BY s.total_sales DESC
LIMIT 100
