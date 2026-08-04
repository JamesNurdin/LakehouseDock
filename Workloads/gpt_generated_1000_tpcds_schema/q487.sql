/*
  Goal: Identify top performing stores in 2001 (CA) by total profit, enriched with the promotions they ran, any intersecting high‑value orders, and customers excluded from a targeted segment. The query demonstrates complex joins across all 12 TPC‑DS tables, applies multiple filters, uses window ranking, scalar sub‑queries, EXISTS, INTERSECT, EXCEPT, UNION, UNNEST, and paginates the final result.
*/
WITH
  /* Sales facts with related dimensions */
  sales AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_ticket_number,
      s.s_store_id,
      s.s_store_name,
      s.s_state,
      d_sales.d_year,
      t.t_hour,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      p.p_response_target,
      p.p_promo_id,
      cd.cd_gender,
      cust.c_customer_id,
      -- scalar sub‑query: average discount on the same day
      (SELECT avg(ss2.ss_ext_discount_amt)
         FROM store_sales ss2
        WHERE ss2.ss_sold_date_sk = ss.ss_sold_date_sk) AS avg_discount_for_day
    FROM store_sales ss
    JOIN date_dim d_sales        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p              ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer cust            ON ss.ss_customer_sk = cust.c_customer_sk
    WHERE d_sales.d_year = 2001
      AND p.p_response_target > 10
      AND s.s_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
  ),

  /* Returns facts with related dimensions */
  returns AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      r.r_reason_desc,
      d_ret.d_year AS return_year,
      cc.cc_name,
      cp.cp_type
    FROM catalog_returns cr
    JOIN date_dim d_ret          ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret          ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN reason r                ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc          ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp         ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d_ret.d_year = 2001
      AND r.r_reason_desc LIKE '%warranty%'
      AND cr.cr_store_credit > 50
  ),

  /* Web page activity */
  web AS (
    SELECT
      wp.wp_web_page_id,
      wp.wp_url,
      cust.c_customer_id,
      d_wp.d_year AS creation_year
    FROM web_page wp
    JOIN date_dim d_wp          ON wp.wp_creation_date_sk = d_wp.d_date_sk
    JOIN customer cust          ON wp.wp_customer_sk = cust.c_customer_sk
    WHERE d_wp.d_year = 2001
  ),

  /* Store closed‑date information */
  store_closed AS (
    SELECT
      s.s_store_sk,
      d_sc.d_year AS closed_year
    FROM store s
    JOIN date_dim d_sc ON s.s_closed_date_sk = d_sc.d_date_sk
    WHERE d_sc.d_year = 2001
  ),

  /* Promotion start / end years */
  promo_dates AS (
    SELECT
      p.p_promo_sk,
      d_start.d_year AS promo_start_year,
      d_end.d_year   AS promo_end_year
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk
    WHERE d_start.d_year = 2001
  ),

  /* Aggregate sales per store */
  combined AS (
    SELECT
      s.s_store_sk,
      s.s_store_id,
      s.s_store_name,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit)       AS total_profit,
      COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
      AVG(ss.avg_discount_for_day) AS avg_discount_day
    FROM sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE EXISTS (
      SELECT 1 FROM returns r WHERE r.cr_order_number = ss.ss_ticket_number
    )
    GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name
  ),

  /* Rank stores by profit */
  ranked AS (
    SELECT
      c.*, 
      ROW_NUMBER() OVER (ORDER BY c.total_profit DESC) AS profit_rank
    FROM combined c
  ),

  /* UNION of distinct store IDs and web page IDs (forces a distinct set) */
  union_ids AS (
    SELECT s.s_store_id FROM store s
    UNION
    SELECT wp.wp_web_page_id FROM web_page wp
  ),

  /* INTERSECT of high‑value orders from sales and returns */
  intersect_orders AS (
    SELECT ss_ticket_number AS order_num FROM store_sales WHERE ss_net_profit > 1000
    INTERSECT
    SELECT cr_order_number FROM catalog_returns WHERE cr_return_amount > 200
  ),

  /* EXCEPT: customers born before 1970 but not flagged as preferred */
  except_customers AS (
    SELECT c.c_customer_id FROM customer c WHERE c.c_birth_year < 1970
    EXCEPT
    SELECT c.c_customer_id FROM customer c WHERE c.c_preferred_cust_flag = 'Y'
  ),

  /* Build an array of distinct promotion IDs per store and UNNEST it */
  promo_array AS (
    SELECT
      ss.ss_store_sk,
      array_agg(DISTINCT p.p_promo_id) AS promo_ids
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY ss.ss_store_sk
  )
SELECT
  r.s_store_id,
  r.s_store_name,
  r.total_sales,
  r.total_profit,
  r.profit_rank,
  promo_id,
  io.order_num,
  ec.c_customer_id AS excluded_customer_id
FROM ranked r
JOIN promo_array pa            ON r.s_store_sk = pa.ss_store_sk
LEFT JOIN UNNEST(pa.promo_ids) AS t(promo_id) ON true
LEFT JOIN intersect_orders io  ON true
LEFT JOIN except_customers ec  ON true
ORDER BY r.profit_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
