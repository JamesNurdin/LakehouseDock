WITH
  sampled_cs AS (
    SELECT cs.cs_bill_customer_sk,
           cs.cs_bill_cdemo_sk,
           cs.cs_ext_sales_price,
           cs.cs_sold_time_sk,
           cs.cs_promo_sk
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)    -- sample roughly 10 % of rows
    WHERE cs.cs_ext_sales_price > 50
  ),

  cs_agg AS (
    SELECT
      cs.cs_bill_customer_sk      AS customer_sk,
      cd.cd_gender,
      cd.cd_marital_status,
      SUM(cs.cs_ext_sales_price)   AS total_sales,
      (
        SELECT SUM(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = cs.cs_bill_customer_sk
      )                           AS total_sales_all_time
    FROM sampled_cs cs
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cs.cs_bill_customer_sk, cd.cd_gender, cd.cd_marital_status
  ),

  sampled_ws AS (
    SELECT ws.ws_bill_customer_sk,
           ws.ws_bill_cdemo_sk,
           ws.ws_ext_sales_price,
           ws.ws_sold_time_sk,
           ws.ws_promo_sk
    FROM web_sales ws
    TABLESAMPLE BERNOULLI (10)
    WHERE ws.ws_ext_sales_price > 50
  ),

  ws_agg AS (
    SELECT
      ws.ws_bill_customer_sk      AS customer_sk,
      cd.cd_gender,
      cd.cd_marital_status,
      SUM(ws.ws_ext_sales_price)   AS total_sales,
      (
        SELECT SUM(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = ws.ws_bill_customer_sk
      )                           AS total_sales_all_time
    FROM sampled_ws ws
    JOIN customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY ws.ws_bill_customer_sk, cd.cd_gender, cd.cd_marital_status
  ),

  union_agg AS (
    SELECT * FROM cs_agg
    UNION DISTINCT
    SELECT * FROM ws_agg
  ),

  promo_set AS (
    SELECT
      cs.cs_bill_customer_sk      AS customer_sk,
      cd.cd_gender,
      cd.cd_marital_status,
      SUM(cs.cs_ext_sales_price)   AS total_sales,
      (
        SELECT SUM(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = cs.cs_bill_customer_sk
      )                           AS total_sales_all_time
    FROM catalog_sales cs
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE p.p_promo_name = 'Clearance'
    GROUP BY cs.cs_bill_customer_sk, cd.cd_gender, cd.cd_marital_status
  ),

  final_set AS (
    SELECT * FROM union_agg
    EXCEPT
    SELECT * FROM promo_set
  )
SELECT
  customer_sk,
  cd_gender,
  cd_marital_status,
  total_sales,
  total_sales_all_time,
  ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM final_set
ORDER BY total_sales DESC
LIMIT 100
