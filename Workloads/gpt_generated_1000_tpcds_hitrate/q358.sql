WITH
  recent_dates AS (
    SELECT d_date_sk, d_year, d_month_seq
    FROM date_dim
    WHERE d_year = 2001
  ),
  store_agg AS (
    SELECT
      c.c_customer_id AS c_id,
      dd.d_month_seq AS m_seq,
      SUM(ss.ss_ext_sales_price) AS sales_amount,
      ss.ss_cdemo_sk AS demo_sk
    FROM store_sales ss
    JOIN recent_dates dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id, dd.d_month_seq, ss.ss_cdemo_sk
    HAVING (
      SELECT cd.cd_credit_rating
      FROM customer_demographics cd
      WHERE cd.cd_demo_sk = ss.ss_cdemo_sk
    ) = 'High Risk'
  ),
  catalog_agg AS (
    SELECT
      c.c_customer_id AS c_id,
      dd.d_month_seq AS m_seq,
      SUM(cs.cs_ext_sales_price) AS sales_amount,
      cs.cs_bill_cdemo_sk AS demo_sk
    FROM catalog_sales cs
    JOIN recent_dates dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id, dd.d_month_seq, cs.cs_bill_cdemo_sk
    HAVING (
      SELECT cd.cd_credit_rating
      FROM customer_demographics cd
      WHERE cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    ) = 'High Risk'
  ),
  combined AS (
    SELECT c_id, m_seq, 'store' AS sales_source, sales_amount, demo_sk
    FROM store_agg
    UNION ALL
    SELECT c_id, m_seq, 'catalog' AS sales_source, sales_amount, demo_sk
    FROM catalog_agg
  )
SELECT
  comb.c_id AS customer_id,
  comb.m_seq AS month_seq,
  comb.sales_source,
  comb.sales_amount,
  LAG(comb.sales_amount) OVER (PARTITION BY comb.c_id ORDER BY comb.m_seq) AS prev_month_sales,
  cd.cd_credit_rating AS credit_rating
FROM combined comb
JOIN customer_demographics cd ON comb.demo_sk = cd.cd_demo_sk
ORDER BY
  customer_id,
  month_seq,
  sales_source
