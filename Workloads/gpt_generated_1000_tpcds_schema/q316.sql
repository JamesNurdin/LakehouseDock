WITH
  promo_sales AS (
    SELECT
      p.p_promo_sk,
      p.p_promo_name,
      SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY p.p_promo_sk, p.p_promo_name
  ),
  web_return_agg AS (
    SELECT
      r.r_reason_sk,
      r.r_reason_desc,
      SUM(wr.wr_return_amt) AS total_returns
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY r.r_reason_sk, r.r_reason_desc
  ),
  -- Small dimension: one hour of the day
  time_filter AS (
    SELECT t.t_time_sk
    FROM time_dim t
    WHERE t.t_hour = 12
  ),
  -- Small set of active promotions
  hourly_promos AS (
    SELECT p.p_promo_sk, p.p_promo_name
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
  ),
  -- CROSS JOIN between the hour and the active promotions
  cross_set AS (
    SELECT tf.t_time_sk, hp.p_promo_sk, hp.p_promo_name
    FROM time_filter tf
    CROSS JOIN hourly_promos hp
  ),
  -- Demonstrate UNNEST of an array built from a column value
  expanded_promos AS (
    SELECT
      cs.t_time_sk,
      cs.p_promo_sk,
      p.p_promo_name,
      u.promo_name_element
    FROM cross_set cs
    JOIN promotion p ON cs.p_promo_sk = p.p_promo_sk
    CROSS JOIN UNNEST(ARRAY[p.p_promo_name]) AS u(promo_name_element)
  ),
  -- EXCEPT to find promotions with sales but without any web sales
  sales_without_returns AS (
    SELECT ps.p_promo_sk
    FROM promo_sales ps
    EXCEPT
    SELECT DISTINCT ws.ws_promo_sk
    FROM web_sales ws
    WHERE ws.ws_promo_sk IS NOT NULL
  )
SELECT src_type,
       key_id,
       description,
       amount
FROM (
  SELECT
    'PROMO' AS src_type,
    ps.p_promo_sk AS key_id,
    ps.p_promo_name AS description,
    ps.total_sales AS amount
  FROM promo_sales ps

  UNION ALL

  SELECT
    'RETURN_REASON' AS src_type,
    wr.r_reason_sk AS key_id,
    wr.r_reason_desc AS description,
    wr.total_returns AS amount
  FROM web_return_agg wr

  UNION ALL

  SELECT
    'NO_RETURN_PROMO' AS src_type,
    sr.p_promo_sk AS key_id,
    NULL AS description,
    CAST(0.0 AS decimal(7,2)) AS amount
  FROM sales_without_returns sr
) combined
ORDER BY amount DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
