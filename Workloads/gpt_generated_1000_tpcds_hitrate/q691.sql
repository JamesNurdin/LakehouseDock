WITH
  sales_agg AS (
    SELECT
      ss.ss_customer_sk,
      SUM(ss.ss_net_profit) AS total_sales_profit,
      SUM(ss.ss_ext_tax) AS total_sales_tax
    FROM
      tpcds.store_sales ss
      TABLESAMPLE BERNOULLI (10)
      JOIN tpcds.date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
      JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
      ds.d_year = 2001
      AND ss.ss_ext_tax > 0
      AND ds.d_holiday = 'N'
    GROUP BY
      ss.ss_customer_sk
  ),
  returns_agg AS (
    SELECT
      cr.cr_refunded_customer_sk AS customer_sk,
      SUM(cr.cr_net_loss) AS total_return_loss,
      COUNT(DISTINCT cr.cr_reason_sk) AS distinct_reason_count,
      MAX(CASE WHEN r.r_reason_desc LIKE '%price%' THEN 1 ELSE 0 END) AS has_price_reason
    FROM
      tpcds.catalog_returns cr
      TABLESAMPLE BERNOULLI (5)
      JOIN tpcds.date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
      JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
      JOIN tpcds.customer_address ca_ret ON cr.cr_refunded_addr_sk = ca_ret.ca_address_sk
    WHERE
      dr.d_year = 2001
      AND r.r_reason_desc LIKE '%price%'
      AND dr.d_holiday = 'N'
    GROUP BY
      cr.cr_refunded_customer_sk
  )
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  ca.ca_city,
  ca.ca_state,
  COALESCE(sa.total_sales_profit, 0) AS total_sales_profit,
  COALESCE(ra.total_return_loss, 0) AS total_return_loss,
  COALESCE(sa.total_sales_profit, 0) - COALESCE(ra.total_return_loss, 0) AS net_impact,
  CASE
    WHEN COALESCE(ra.total_return_loss, 0) > 1000 THEN 'High Loss'
    WHEN COALESCE(ra.total_return_loss, 0) > 100 THEN 'Medium Loss'
    ELSE 'Low Loss'
  END AS loss_category,
  ra.distinct_reason_count,
  ra.has_price_reason,
  RANK() OVER (ORDER BY (COALESCE(sa.total_sales_profit, 0) - COALESCE(ra.total_return_loss, 0)) DESC) AS profit_rank
FROM
  tpcds.customer c
  JOIN tpcds.customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  LEFT JOIN sales_agg sa ON c.c_customer_sk = sa.ss_customer_sk
  LEFT JOIN returns_agg ra ON c.c_customer_sk = ra.customer_sk
WHERE
  ca.ca_country = 'United States'
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_birth_year BETWEEN 1950 AND 2000
ORDER BY
  profit_rank
LIMIT 100
