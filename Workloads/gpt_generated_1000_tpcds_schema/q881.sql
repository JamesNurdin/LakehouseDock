WITH filtered_items AS (
   SELECT i_item_sk,
          i_item_desc,
          i_formulation,
          i_container
   FROM item
   WHERE regexp_like(i_formulation, '[a-z]+[0-9]+')
     AND i_container LIKE '%Unknown%'
)

SELECT
   f.i_item_sk,
   f.i_item_desc,
   SUM(ss.ss_ext_sales_price) AS total_sales,
   (SELECT COALESCE(SUM(cr.cr_return_amount), 0)
    FROM catalog_returns cr
    WHERE cr.cr_item_sk = f.i_item_sk) AS total_return_amount,
   (SELECT COUNT(*)
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = f.i_item_sk
      AND ws2.ws_net_profit > 0) AS web_positive_profit_cnt
FROM filtered_items f
JOIN store_sales ss ON ss.ss_item_sk = f.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2000
  AND f.i_item_sk IN (SELECT cr_item_sk FROM catalog_returns WHERE cr_return_amount > 0)
  AND regexp_like(d.d_day_name, '^S')
GROUP BY f.i_item_sk, f.i_item_desc
HAVING SUM(ss.ss_ext_sales_price) > 500

UNION DISTINCT

SELECT
   f.i_item_sk,
   f.i_item_desc,
   SUM(ws.ws_ext_sales_price) AS total_sales,
   (SELECT COALESCE(SUM(cr.cr_return_amount), 0)
    FROM catalog_returns cr
    WHERE cr.cr_item_sk = f.i_item_sk) AS total_return_amount,
   (SELECT COUNT(*)
    FROM store_sales ss2
    WHERE ss2.ss_item_sk = f.i_item_sk
      AND ss2.ss_net_profit > 0) AS store_positive_profit_cnt
FROM filtered_items f
JOIN web_sales ws ON ws.ws_item_sk = f.i_item_sk
JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
WHERE d2.d_year = 2000
  AND f.i_item_desc LIKE '%toy%'
  AND EXISTS (
        SELECT 1
        FROM reason r
        JOIN catalog_returns cr ON cr.cr_reason_sk = r.r_reason_sk
        WHERE cr.cr_item_sk = f.i_item_sk
          AND r.r_reason_desc LIKE '%defect%'
      )
GROUP BY f.i_item_sk, f.i_item_desc
HAVING SUM(ws.ws_ext_sales_price) > 500

ORDER BY total_sales DESC
LIMIT 100
