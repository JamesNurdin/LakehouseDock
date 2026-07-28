WITH
  web_raw AS (
    SELECT
      w.web_state                                   AS region,
      p.p_channel_email                            AS channel,
      SUM(ws.ws_net_paid)                         AS total_net_paid,
      COUNT(*)                                    AS sales_cnt,
      CONCAT(w.web_state, ':', COALESCE(p.p_channel_email, 'ALL')) AS full_desc,
      ROW_NUMBER() OVER (PARTITION BY w.web_state ORDER BY SUM(ws.ws_net_paid) DESC) AS rn
    FROM
      web_sales ws
      JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
      JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
      regexp_like(w.web_manager, 'John|Richard')
      AND w.web_street_type LIKE 'W%'
    GROUP BY
      GROUPING SETS (
        (w.web_state, p.p_channel_email),
        (w.web_state),
        ()
      )
  ),
  web_agg AS (
    SELECT region, channel, total_net_paid, sales_cnt, full_desc
    FROM web_raw
    WHERE rn = 1
  ),
  store_raw AS (
    SELECT
      s.s_state                                    AS region,
      p.p_channel_email                           AS channel,
      SUM(ss.ss_net_paid)                        AS total_net_paid,
      COUNT(*)                                   AS sales_cnt,
      CONCAT(s.s_state, ':', COALESCE(p.p_channel_email, 'ALL')) AS full_desc,
      ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(ss.ss_net_paid) DESC) AS rn
    FROM
      store_sales ss
      JOIN store s ON ss.ss_store_sk = s.s_store_sk
      JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE
      regexp_like(s.s_city, '^A')
      AND s.s_country LIKE 'U%'
    GROUP BY
      GROUPING SETS (
        (s.s_state, p.p_channel_email),
        (s.s_state),
        ()
      )
  ),
  store_agg AS (
    SELECT region, channel, total_net_paid, sales_cnt, full_desc
    FROM store_raw
    WHERE rn = 1
  )
SELECT
  region,
  channel,
  total_net_paid,
  sales_cnt,
  full_desc
FROM (
  SELECT region, channel, total_net_paid, sales_cnt, full_desc FROM web_agg
  UNION ALL
  SELECT region, channel, total_net_paid, sales_cnt, full_desc FROM store_agg
) AS combined
ORDER BY
  region,
  channel
LIMIT 100
