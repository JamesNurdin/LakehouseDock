WITH sales_enriched AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_sold_time_sk,
       ss.ss_store_sk,
       ss.ss_addr_sk,
       ss.ss_promo_sk,
       ss.ss_net_paid,
       ss.ss_quantity,
       ss.ss_ext_sales_price,
       t.t_hour,
       t.t_meal_time,
       ca.ca_city,
       ca.ca_state,
       p.p_promo_name,
       s.s_store_name,
       s.s_market_manager,
       (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_sk = ss.ss_promo_sk) AS max_promo_cost
   FROM store_sales ss
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE ss.ss_ext_sales_price > 100
     AND ss.ss_quantity >= 1
     AND t.t_hour BETWEEN 9 AND 20
     AND ca.ca_state = 'CA'
     AND p.p_channel_email = 'N'
),

store_time_summary AS (
   SELECT
       ss.ss_store_sk,
       t.t_hour,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       COUNT(*) AS sales_cnt
   FROM store_sales ss
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   GROUP BY ss.ss_store_sk, t.t_hour
),

full_joined AS (
   SELECT
       COALESCE(sts.ss_store_sk, se.ss_store_sk) AS store_sk,
       COALESCE(sts.t_hour,   se.t_hour)    AS hour,
       sts.total_sales                         AS summary_sales,
       se.ss_ext_sales_price                   AS sale_amount,
       sts.sales_cnt
   FROM store_time_summary sts
   FULL OUTER JOIN sales_enriched se
       ON sts.ss_store_sk = se.ss_store_sk
      AND sts.t_hour      = se.t_hour
),

unioned AS (
   SELECT store_sk, hour, summary_sales AS metric
   FROM full_joined
   WHERE summary_sales IS NOT NULL
   UNION DISTINCT
   SELECT store_sk, hour, sale_amount AS metric
   FROM full_joined
   WHERE sale_amount IS NOT NULL
),

intersected AS (
   SELECT store_sk, hour, metric
   FROM unioned
   INTERSECT
   SELECT store_sk, hour, metric
   FROM unioned
   WHERE metric > 200
),

aggregated AS (
   SELECT
       store_sk,
       hour,
       metric,
       COUNT(*) AS cnt
   FROM intersected
   GROUP BY CUBE (store_sk, hour, metric)
   HAVING COUNT(*) > 0
)
SELECT
    store_sk,
    hour,
    metric,
    cnt,
    ROW_NUMBER() OVER (PARTITION BY hour ORDER BY metric DESC) AS rn,
    CASE WHEN metric = (
           SELECT MAX(metric) FROM aggregated a2 WHERE a2.hour = aggregated.hour
         ) THEN 'Top' ELSE 'Other' END AS rank_flag
FROM aggregated
ORDER BY hour ASC, metric DESC
LIMIT 100
