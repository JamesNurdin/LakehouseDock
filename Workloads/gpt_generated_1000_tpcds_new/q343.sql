WITH
  joined_data AS (
    SELECT
      cs.cs_bill_customer_sk,
      cs.cs_ship_customer_sk,
      cs.cs_ext_list_price,
      cs.cs_ext_discount_amt,
      cs.cs_net_paid,
      ca.ca_zip,
      ca.ca_street_type,
      hd.hd_buy_potential,
      hd.hd_dep_count
    FROM catalog_sales cs
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ca.ca_zip = '75124'
      AND hd.hd_buy_potential = '5001-10000'
      AND cs.cs_ext_list_price > 1000
  ),
  full_outer_sales AS (
    SELECT
      cs.cs_bill_customer_sk,
      cs.cs_ship_customer_sk,
      cs.cs_ext_discount_amt,
      cs.cs_net_paid,
      ca.ca_state,
      ca.ca_zip
    FROM catalog_sales cs
    FULL OUTER JOIN customer_address ca
      ON cs.cs_ship_addr_sk = ca.ca_address_sk
    WHERE cs.cs_ext_discount_amt IS NOT NULL
  ),
  scalar_max_price AS (
    SELECT MAX(cs_ext_list_price) AS max_price
    FROM catalog_sales
    WHERE cs_ext_list_price > 0
  ),
  intersect_keys AS (
    SELECT cs_bill_customer_sk AS cust_key
    FROM joined_data
    WHERE cs_ext_discount_amt > 0
    INTERSECT
    SELECT cs_ship_customer_sk
    FROM full_outer_sales
    WHERE cs_ext_discount_amt > 0
  ),
  union_agg AS (
    SELECT
      cust_key,
      COUNT(*) AS cnt,
      SUM(cs_net_paid) AS total_paid
    FROM (
      SELECT cs_bill_customer_sk AS cust_key, cs_net_paid
      FROM catalog_sales
      WHERE cs_ext_list_price > 2000
      UNION
      SELECT cs_ship_customer_sk, cs_net_paid
      FROM catalog_sales
      WHERE cs_ext_list_price > 2000
    ) u
    GROUP BY cust_key
  )
SELECT
  jd.ca_zip,
  jd.ca_street_type,
  jd.hd_buy_potential,
  CASE WHEN jd.cs_ext_discount_amt > 0 THEN 'Discounted' ELSE 'Fullprice' END AS discount_category,
  SUM(jd.cs_net_paid) AS total_net_paid,
  AVG(jd.cs_ext_discount_amt) AS avg_discount_amt,
  COUNT(DISTINCT jd.cs_bill_customer_sk) AS distinct_bill_customers,
  (SELECT max_price FROM scalar_max_price) AS max_list_price_overall,
  ik.cust_key AS intersect_customer_key,
  ua.cnt,
  ua.total_paid
FROM joined_data jd
LEFT JOIN intersect_keys ik ON jd.cs_bill_customer_sk = ik.cust_key
LEFT JOIN union_agg ua ON jd.cs_bill_customer_sk = ua.cust_key
GROUP BY
  jd.ca_zip,
  jd.ca_street_type,
  jd.hd_buy_potential,
  CASE WHEN jd.cs_ext_discount_amt > 0 THEN 'Discounted' ELSE 'Fullprice' END,
  (SELECT max_price FROM scalar_max_price),
  ik.cust_key,
  ua.cnt,
  ua.total_paid
ORDER BY total_net_paid DESC
LIMIT 100
