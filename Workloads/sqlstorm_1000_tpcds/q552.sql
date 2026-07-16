WITH
  cat AS (
    SELECT 
      d.d_year,
      d.d_month_seq AS d_month,
      i.i_category,
      p.p_promo_id,
      SUM(cs.cs_ext_sales_price) AS sales,
      SUM(cs.cs_net_profit) AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category, p.p_promo_id
  ),
  store AS (
    SELECT 
      d.d_year,
      d.d_month_seq AS d_month,
      i.i_category,
      p.p_promo_id,
      SUM(ss.ss_ext_sales_price) AS sales,
      SUM(ss.ss_net_profit) AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category, p.p_promo_id
  ),
  web AS (
    SELECT 
      d.d_year,
      d.d_month_seq AS d_month,
      i.i_category,
      p.p_promo_id,
      SUM(ws.ws_ext_sales_price) AS sales,
      SUM(ws.ws_net_profit) AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category, p.p_promo_id
  )
SELECT 
  channel,
  d_year,
  d_month,
  i_category,
  p_promo_id,
  SUM(sales) AS total_sales,
  SUM(profit) AS total_profit
FROM (
  SELECT 'catalog' AS channel, * FROM cat
  UNION ALL
  SELECT 'store' AS channel, * FROM store
  UNION ALL
  SELECT 'web' AS channel, * FROM web
) x
GROUP BY channel, d_year, d_month, i_category, p_promo_id
ORDER BY total_sales DESC
LIMIT 100
