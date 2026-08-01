WITH
  filtered_sales AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_call_center_sk,
      cs.cs_promo_sk,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      d.d_month_seq,
      d.d_year,
      t.t_hour,
      cc.cc_call_center_sk,
      cc.cc_call_center_id,
      cc.cc_state,
      p.p_promo_sk,
      p.p_promo_id,
      p.p_channel_catalog,
      s.s_store_id,
      s.s_state
    FROM catalog_sales cs
    FULL OUTER JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store s
      ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND p.p_channel_catalog = 'N'
      AND s.s_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND cs.cs_quantity > 5
  ),

  agg_by_cc_promo AS (
    SELECT
      cc_call_center_sk,
      cc_call_center_id,
      p_promo_id,
      d_month_seq,
      SUM(cs_ext_sales_price) AS month_sales,
      SUM(cs_net_profit) AS month_profit,
      SUM(cs_quantity) AS month_quantity
    FROM filtered_sales
    GROUP BY cc_call_center_sk, cc_call_center_id, p_promo_id, d_month_seq
  ),

  union_promos AS (
    SELECT DISTINCT p.p_promo_id
    FROM promotion p
    WHERE p.p_start_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    UNION
    SELECT DISTINCT p.p_promo_id
    FROM promotion p
    JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
  ),

  promos_without_sales AS (
    SELECT p.p_promo_id
    FROM promotion p
    WHERE p.p_start_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    EXCEPT
    SELECT DISTINCT p.p_promo_id
    FROM promotion p
    JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
  )

SELECT
  a.cc_call_center_id,
  a.p_promo_id,
  AVG(a.month_sales) AS avg_month_sales,
  SUM(a.month_profit) AS total_profit,
  (
    SELECT SUM(cs2.cs_ext_sales_price)
    FROM catalog_sales cs2
    WHERE cs2.cs_call_center_sk = a.cc_call_center_sk
  ) AS overall_sales_by_cc,
  COUNT(DISTINCT a.d_month_seq) AS active_months,
  (
    SELECT COUNT(*)
    FROM union_promos up
    WHERE up.p_promo_id = a.p_promo_id
  ) AS promo_in_union_flag
FROM agg_by_cc_promo a
WHERE a.month_sales > 1000
  AND a.month_quantity > 50
  AND a.d_month_seq BETWEEN 1 AND 12
GROUP BY a.cc_call_center_id, a.p_promo_id, a.cc_call_center_sk
HAVING SUM(a.month_profit) > 0
ORDER BY avg_month_sales DESC
LIMIT 100
