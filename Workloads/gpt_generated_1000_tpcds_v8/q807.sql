WITH
base_sales AS (
  SELECT
    cs.cs_bill_customer_sk,
    cs.cs_bill_cdemo_sk,
    cs.cs_sales_price,
    cs.cs_net_paid_inc_ship_tax,
    ARRAY[cs.cs_sales_price, cs.cs_net_paid_inc_ship_tax] AS price_array
  FROM catalog_sales cs
  WHERE cs.cs_sales_price > 10
    AND cs.cs_net_paid_inc_ship_tax BETWEEN 500 AND 6000
    AND cs.cs_quantity >= 1
    AND cs.cs_ship_mode_sk IS NOT NULL
    AND cs.cs_item_sk IN (SELECT cs_item_sk FROM catalog_sales WHERE cs_quantity > 0 LIMIT 1)
),
sales_unnest AS (
  SELECT
    bs.cs_bill_customer_sk,
    bs.cs_bill_cdemo_sk,
    price
  FROM base_sales bs
  CROSS JOIN UNNEST(bs.price_array) AS t(price)
),
sales_cust_full AS (
  SELECT
    COALESCE(s.cs_bill_customer_sk, c.c_customer_sk) AS customer_sk,
    s.price,
    c.c_first_name,
    c.c_last_name,
    cd.cd_education_status,
    cd.cd_dep_count
  FROM sales_unnest s
  FULL OUTER JOIN customer c
    ON s.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd
    ON COALESCE(s.cs_bill_cdemo_sk, c.c_current_cdemo_sk) = cd.cd_demo_sk
  WHERE (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
    AND (cd.cd_dep_count IS NULL OR cd.cd_dep_count <= 3)
    AND (s.price > 20 OR s.price IS NULL)
),
returns_join AS (
  SELECT
    sr.sr_customer_sk,
    sr.sr_return_amt,
    sr.sr_refunded_cash,
    cd.cd_gender,
    cd.cd_education_status
  FROM store_returns sr
  JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE sr.sr_return_amt > 20
    AND sr.sr_refunded_cash < 200
    AND cd.cd_education_status LIKE '%Degree%'
    AND sr.sr_store_credit > 10
    AND sr.sr_net_loss IS NOT NULL
),
web_join AS (
  SELECT
    wp.wp_web_page_id,
    wp.wp_type,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name
  FROM web_page wp
  JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
  WHERE wp.wp_type = 'content'
    AND wp.wp_char_count > 1000
    AND wp.wp_link_count >= 5
    AND wp.wp_image_count BETWEEN 1 AND 20
    AND wp.wp_autogen_flag = 'N'
),
union_aggregated AS (
  SELECT
    customer_sk,
    education,
    total_price
  FROM (
    SELECT
      customer_sk,
      cd_education_status AS education,
      SUM(price) AS total_price
    FROM sales_cust_full
    GROUP BY GROUPING SETS ((customer_sk, cd_education_status), (customer_sk), ())
    UNION DISTINCT
    SELECT
      sr_customer_sk AS customer_sk,
      cd_education_status AS education,
      SUM(sr_return_amt) AS total_price
    FROM returns_join
    GROUP BY GROUPING SETS ((sr_customer_sk, cd_education_status), (sr_customer_sk), ())
  ) u
)
SELECT DISTINCT
  ua.customer_sk,
  ua.education,
  ua.total_price,
  RANK() OVER (ORDER BY ua.total_price DESC) AS price_rank
FROM union_aggregated ua
WHERE NOT EXISTS (
  SELECT 1
  FROM web_join w
  WHERE w.c_customer_sk = ua.customer_sk
)
ORDER BY ua.total_price DESC, ua.education
OFFSET 0
LIMIT 100
