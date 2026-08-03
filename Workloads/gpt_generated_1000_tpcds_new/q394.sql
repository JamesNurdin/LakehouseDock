WITH
  store_agg AS (
    SELECT
      d_sold.d_year AS sales_year,
      p.p_promo_name,
      CAST(NULL AS varchar) AS cc_name,
      SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c1 ON ss.ss_customer_sk = c1.c_customer_sk
    JOIN customer_demographics cd1 ON c1.c_current_cdemo_sk = cd1.cd_demo_sk
    JOIN customer_address ca1 ON ss.ss_addr_sk = ca1.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_page wp ON wp.wp_customer_sk = c1.c_customer_sk
                     AND wp.wp_creation_date_sk = d_sold.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
    WHERE cd1.cd_dep_employed_count > 0
    GROUP BY d_sold.d_year, p.p_promo_name
  ),
  catalog_agg AS (
    SELECT
      d_sold.d_year AS sales_year,
      p.p_promo_name,
      cc.cc_name,
      SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c2 ON cs.cs_bill_customer_sk = c2.c_customer_sk
    JOIN customer_demographics cd2 ON c2.c_current_cdemo_sk = cd2.cd_demo_sk
    WHERE EXISTS (
        SELECT 1
        FROM customer_demographics cd3
        WHERE cd3.cd_demo_sk = cs.cs_bill_cdemo_sk
          AND cd3.cd_dep_employed_count > 0
    )
    GROUP BY d_sold.d_year, p.p_promo_name, cc.cc_name
  ),
  active_exclude AS (
    SELECT
      d_sold.d_year AS sales_year,
      p.p_promo_name,
      cc.cc_name,
      SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY d_sold.d_year, p.p_promo_name, cc.cc_name
  )
SELECT *
FROM (
  SELECT sales_year, p_promo_name, cc_name, total_net_paid FROM store_agg
  UNION DISTINCT
  SELECT sales_year, p_promo_name, cc_name, total_net_paid FROM catalog_agg
) AS union_all
EXCEPT
SELECT sales_year, p_promo_name, cc_name, total_net_paid FROM active_exclude
ORDER BY sales_year DESC, total_net_paid DESC
LIMIT 100
