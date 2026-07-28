WITH
  store_agg AS (
    SELECT
      concat('Store_', s.s_store_id) AS channel_id,
      i.i_item_id,
      i.i_item_desc,
      substr(i.i_item_desc, 1, 30) AS short_desc,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(*) AS cnt_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)bike')
      AND s.s_store_name LIKE '%Super%'
    GROUP BY s.s_store_id, i.i_item_id, i.i_item_desc
  ),
  web_agg AS (
    SELECT
      concat('Web_', CAST(ws.ws_web_page_sk AS varchar)) AS channel_id,
      i.i_item_id,
      i.i_item_desc,
      substr(i.i_item_desc, 1, 30) AS short_desc,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(*) AS cnt_sales
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)bike')
      AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
          AND p.p_discount_active = 'Y'
      )
    GROUP BY ws.ws_web_page_sk, i.i_item_id, i.i_item_desc
  ),
  combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
  ),
  with_avg AS (
    SELECT
      c.channel_id,
      c.i_item_id,
      c.i_item_desc,
      c.short_desc,
      c.total_sales,
      c.cnt_sales,
      (SELECT AVG(total_sales) FROM combined) AS avg_total_sales_overall
    FROM combined c
  )
SELECT
  channel_id,
  i_item_id,
  i_item_desc,
  short_desc,
  total_sales,
  cnt_sales,
  total_sales - avg_total_sales_overall AS sales_vs_avg,
  row_number() OVER (PARTITION BY channel_id ORDER BY total_sales DESC) AS sales_rank
FROM with_avg
WHERE total_sales > avg_total_sales_overall
ORDER BY channel_id, sales_rank
LIMIT 100
