WITH catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_ext_sales_price) AS cat_sales,
        SUM(cs.cs_net_profit) AS cat_profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_purchase_estimate >= 6000
      AND i.i_brand = 'Brand#45'
      AND cs.cs_sold_date_sk BETWEEN 2451500 AND 2451600
      AND cs.cs_ext_discount_amt < 50.00
    GROUP BY cs.cs_bill_customer_sk, cs.cs_item_sk
),
store_agg AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_dep_college_count >= 1
      AND i.i_category = 'Electronics'
      AND ss.ss_sold_date_sk BETWEEN 2451500 AND 2451600
      AND ss.ss_ext_sales_price > 80.00
    GROUP BY ss.ss_customer_sk, ss.ss_item_sk
)
SELECT
    ca.cust_sk,
    c.c_first_name,
    c.c_last_name,
    SUM(ca.cat_sales) AS total_catalog_sales,
    SUM(sa.store_sales) AS total_store_sales,
    COUNT(*) AS distinct_items,
    (SELECT COUNT(*)
       FROM store_sales ss2
       WHERE ss2.ss_customer_sk = ca.cust_sk) AS total_store_transactions
FROM catalog_agg ca
JOIN store_agg sa
  ON ca.cust_sk = sa.cust_sk
 AND ca.item_sk = sa.item_sk
JOIN customer c
  ON ca.cust_sk = c.c_customer_sk
WHERE ca.cat_sales > 200.00
  AND sa.store_sales > 150.00
  AND ca.cat_profit > 50.00
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_birth_year BETWEEN 1950 AND 1990
GROUP BY ca.cust_sk, c.c_first_name, c.c_last_name
HAVING SUM(ca.cat_sales) > 1000.00
ORDER BY total_catalog_sales DESC
LIMIT 100
