WITH
  ss AS (
    SELECT
      ss.ss_sold_date_sk,
      d.d_date,
      ss.ss_store_sk,
      s.s_store_name,
      ss.ss_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      ss.ss_quantity,
      ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY ss.ss_ext_sales_price DESC) AS sales_rank
    FROM store_sales ss
    JOIN date_dim d              ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s                 ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c              ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t              ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND ss.ss_quantity > 5
      AND ss.ss_ext_sales_price > 1000
      AND cd.cd_gender = 'M'
  ),

  cs AS (
    SELECT
      cs.cs_sold_date_sk,
      d.d_date,
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cs.cs_order_number,
      p.p_promo_name,
      ROW_NUMBER() OVER (PARTITION BY cs.cs_promo_sk ORDER BY cs.cs_ext_sales_price DESC) AS promo_rank
    FROM catalog_sales cs
    JOIN date_dim d              ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t              ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND cs.cs_quantity > 3
      AND cs.cs_ext_sales_price > 500
      AND p.p_discount_active = 'Y'
      AND cd.cd_education_status = 'College'
      AND cs.cs_item_sk IN (SELECT cr_item_sk FROM catalog_returns WHERE cr_return_quantity > 0)
  ),

  union_set AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.sales_rank        AS rank_val,
           ss.ss_ext_sales_price AS metric
    FROM ss
    UNION
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.promo_rank       AS rank_val,
           cs.cs_ext_sales_price AS metric
    FROM cs
  ),

  except_set AS (
    SELECT cs_order_number FROM cs
    EXCEPT
    SELECT cr_order_number FROM catalog_returns
  ),

  final AS (
    SELECT
      u.date_sk,
      d.d_date,
      u.rank_val,
      u.metric,
      COUNT(*) OVER (PARTITION BY u.rank_val) AS cnt_by_rank,
      CASE WHEN u.metric > 2000 THEN 'High' ELSE 'Medium' END AS metric_category
    FROM union_set u
    JOIN date_dim d ON u.date_sk = d.d_date_sk
    WHERE u.rank_val IS NOT NULL
      AND d.d_month_seq BETWEEN 1200 AND 1300
  )
SELECT
  f.d_date,
  f.rank_val,
  f.metric,
  f.cnt_by_rank,
  f.metric_category,
  (SELECT COUNT(*) FROM except_set) AS orders_without_return
FROM final f
FULL OUTER JOIN web_page wp ON wp.wp_creation_date_sk = f.date_sk
WHERE wp.wp_type = 'article' OR wp.wp_type IS NULL
ORDER BY f.metric DESC
LIMIT 100
