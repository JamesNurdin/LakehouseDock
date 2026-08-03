WITH
  store_agg AS (
    SELECT
      p.p_promo_sk        AS promo_sk,
      p.p_promo_name      AS promo_name,
      td.t_shift          AS shift,
      SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN promotion p       ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td       ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY p.p_promo_sk, p.p_promo_name, td.t_shift
  ),
  web_agg AS (
    SELECT
      p.p_promo_sk        AS promo_sk,
      p.p_promo_name      AS promo_name,
      td.t_shift          AS shift,
      SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN promotion p       ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim td       ON ws.ws_sold_time_sk = td.t_time_sk
    GROUP BY p.p_promo_sk, p.p_promo_name, td.t_shift
  ),
  combined AS (
    SELECT promo_sk, promo_name, shift, total_sales FROM store_agg
    UNION ALL
    SELECT promo_sk, promo_name, shift, total_sales FROM web_agg
  ),
  cube_agg AS (
    SELECT
      p.p_promo_name   AS promo_name,
      c.shift           AS shift,
      SUM(c.total_sales) AS total_sales
    FROM combined c
    RIGHT JOIN promotion p ON p.p_promo_sk = c.promo_sk
    GROUP BY CUBE(p.p_promo_name, c.shift)
  ),
  ranked AS (
    SELECT
      promo_name,
      shift,
      total_sales,
      ROW_NUMBER() OVER (PARTITION BY promo_name ORDER BY total_sales DESC) AS rnk
    FROM cube_agg
  )
SELECT
  promo_name,
  shift,
  total_sales,
  rnk
FROM ranked
WHERE rnk <= 5
ORDER BY total_sales DESC
LIMIT 100
