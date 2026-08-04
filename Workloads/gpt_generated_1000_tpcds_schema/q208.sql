WITH store_part AS (
   SELECT
      i.i_item_id,
      i.i_item_desc,
      SUM(ss.ss_net_paid_inc_tax) AS total_sales,
      'store' AS sales_source
   FROM store_sales ss TABLESAMPLE BERNOULLI (10)
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   WHERE td.t_hour BETWEEN 9 AND 17
   GROUP BY i.i_item_id, i.i_item_desc
),
web_part AS (
   SELECT
      i2.i_item_id,
      i2.i_item_desc,
      COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS total_sales,
      'web' AS sales_source
   FROM web_sales ws
   FULL OUTER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
   JOIN time_dim td2 ON ws.ws_sold_time_sk = td2.t_time_sk
   WHERE td2.t_hour BETWEEN 9 AND 17
     AND EXISTS (
        SELECT 1
        FROM catalog_sales cs
        JOIN item i3 ON cs.cs_item_sk = i3.i_item_sk
        WHERE i3.i_item_sk = i2.i_item_sk
          AND cs.cs_sold_time_sk = td2.t_time_sk
     )
   GROUP BY i2.i_item_id, i2.i_item_desc
)
SELECT *
FROM store_part
UNION
SELECT *
FROM web_part
LIMIT 100
