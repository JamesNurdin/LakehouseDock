WITH
  store_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      p.p_promo_name,
      SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY ROLLUP (d.d_year, d.d_month_seq, p.p_promo_name)
  ),
  web_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      p.p_promo_name,
      SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY ROLLUP (d.d_year, d.d_month_seq, p.p_promo_name)
  ),
  full_join AS (
    SELECT
      COALESCE(sa.d_year, wa.d_year)        AS year,
      COALESCE(sa.d_month_seq, wa.d_month_seq) AS month_seq,
      COALESCE(sa.p_promo_name, wa.p_promo_name) AS promo_name,
      sa.total_sales                       AS store_sales,
      wa.total_sales                       AS web_sales
    FROM store_agg sa
    FULL OUTER JOIN web_agg wa
      ON sa.d_year = wa.d_year
     AND sa.d_month_seq = wa.d_month_seq
     AND sa.p_promo_name = wa.p_promo_name
  ),
  promo_channels AS (
    SELECT
      p.p_promo_name,
      t.channel
    FROM promotion p
    CROSS JOIN UNNEST(ARRAY[p.p_channel_email, p.p_channel_tv, p.p_channel_radio]) AS t(channel)
    WHERE t.channel IS NOT NULL
    GROUP BY p.p_promo_name, t.channel
  ),
  exclusive_web_items AS (
    SELECT ws.ws_item_sk
    FROM web_sales ws
    EXCEPT
    SELECT ss.ss_item_sk
    FROM store_sales ss
  ),
  anti_semi_items AS (
    SELECT DISTINCT ws.ws_item_sk
    FROM web_sales ws
    WHERE ws.ws_item_sk NOT IN (SELECT ss.ss_item_sk FROM store_sales ss)
  )
SELECT
  fj.year,
  fj.month_seq,
  fj.promo_name,
  fj.store_sales,
  fj.web_sales,
  pc.channel
FROM full_join fj
LEFT JOIN promo_channels pc
  ON fj.promo_name = pc.p_promo_name
WHERE fj.year IS NOT NULL
UNION
SELECT
  NULL AS year,
  NULL AS month_seq,
  'Exclusive_Web_Item' AS promo_name,
  NULL AS store_sales,
  NULL AS web_sales,
  CAST(ewi.ws_item_sk AS VARCHAR) AS channel
FROM exclusive_web_items ewi
UNION
SELECT
  NULL AS year,
  NULL AS month_seq,
  'AntiSemi_Item' AS promo_name,
  NULL AS store_sales,
  NULL AS web_sales,
  CAST(ai.ws_item_sk AS VARCHAR) AS channel
FROM anti_semi_items ai
WHERE ai.ws_item_sk NOT IN (SELECT ws_item_sk FROM exclusive_web_items)
ORDER BY year DESC NULLS LAST, month_seq, promo_name
