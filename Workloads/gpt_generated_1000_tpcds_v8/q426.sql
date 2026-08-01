WITH
  /* Join all five tables with the required join rules and apply several filters */
  base_data AS (
    SELECT
      ws.ws_order_number,
      ws.ws_web_site_sk,
      ws.ws_promo_sk,
      ws.ws_list_price,
      ws.ws_net_paid_inc_tax,
      ws.ws_ship_date_sk,
      ws.ws_item_sk,
      s.web_name,
      s.web_state,
      s.web_mkt_desc,
      p.p_promo_name,
      p.p_discount_active,
      p.p_channel_email,
      r.r_reason_desc,
      wr.wr_return_amt,
      -- classify promotion status
      CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status
    FROM web_sales ws
    JOIN web_site s
      ON ws.ws_web_site_sk = s.web_site_sk
    LEFT JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
     AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ws.ws_list_price > 100
      AND s.web_state = 'IN'
      AND (p.p_channel_email = 'N' OR p.p_channel_email IS NULL)
      AND ws.ws_ship_date_sk BETWEEN 2451545 AND 2452280
      AND ws.ws_order_number IN (
            SELECT ws_order_number FROM web_sales WHERE ws_list_price > 200
            INTERSECT
            SELECT wr_order_number FROM web_returns WHERE wr_reason_sk = (
                SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%damaged%' LIMIT 1
            )
          )
  ),

  /* Aggregate per web site and promotion status */
  site_promo_agg AS (
    SELECT
      ws_web_site_sk AS site_sk,
      web_name,
      web_state,
      promo_status,
      SUM(ws_net_paid_inc_tax)                        AS total_sales,
      SUM(COALESCE(wr_return_amt, 0))                AS total_returns,
      COUNT(DISTINCT ws_order_number)                AS num_orders
    FROM base_data
    GROUP BY ws_web_site_sk, web_name, web_state, promo_status
  ),

  /* UNION DISTINCT two metric streams */
  union_data AS (
    SELECT site_sk, total_sales  AS metric, 'sales'    AS metric_type FROM site_promo_agg
    UNION DISTINCT
    SELECT site_sk, total_returns AS metric, 'returns' AS metric_type FROM site_promo_agg
  ),

  /* Summarise the UNION result */
  site_aggregated AS (
    SELECT
      site_sk,
      metric_type,
      SUM(metric) AS metric_sum,
      AVG(metric) AS metric_avg,
      COUNT(*)    AS metric_cnt
    FROM union_data
    GROUP BY site_sk, metric_type
  ),

  /* Demonstrate a FULL OUTER JOIN between two tables */
  full_join_orders AS (
    SELECT
      s.ws_order_number AS order_number,
      s.ws_net_paid_inc_tax AS sales_amount,
      r.wr_return_amt      AS return_amount
    FROM web_sales s
    FULL OUTER JOIN web_returns r
      ON s.ws_order_number = r.wr_order_number
    WHERE s.ws_list_price > 150 OR r.wr_return_amt > 0
  )

SELECT
  sa.site_sk,
  sa.metric_type,
  sa.metric_sum,
  sa.metric_avg,
  -- correlated scalar subquery: count distinct return reasons for the site
  (
    SELECT COUNT(DISTINCT r.r_reason_sk)
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ws.ws_web_site_sk = sa.site_sk
  ) AS distinct_return_reasons,
  -- correlated scalar subquery: total return amount for the site
  (
    SELECT SUM(wr2.wr_return_amt)
    FROM web_returns wr2
    JOIN web_sales ws2 ON wr2.wr_order_number = ws2.ws_order_number
    WHERE ws2.ws_web_site_sk = sa.site_sk
  ) AS site_total_return_amount
FROM site_aggregated sa
WHERE sa.metric_sum > 0
ORDER BY sa.site_sk, sa.metric_type
