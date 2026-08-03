WITH store_sales_agg AS (
   SELECT
       d.d_date,
       s.s_store_name,
       SUM(ss.ss_ext_sales_price) AS store_sales_total,
       ARRAY_AGG(DISTINCT cd.cd_gender) AS genders_array
   FROM store_sales ss
   JOIN date_dim d        ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s           ON ss.ss_store_sk = s.s_store_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year = 2002
   GROUP BY d.d_date, s.s_store_name
),
web_sales_agg AS (
   SELECT
       d.d_date,
       w.web_name,
       SUM(ws.ws_ext_sales_price) AS web_sales_total,
       ARRAY_AGG(DISTINCT cd.cd_gender) AS genders_array
   FROM web_sales ws
   JOIN date_dim d        ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_site w        ON ws.ws_web_site_sk = w.web_site_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year = 2002
   GROUP BY d.d_date, w.web_name
),
full_join AS (
   SELECT
       COALESCE(ss.d_date, ws.d_date)               AS sale_date,
       ss.s_store_name,
       ws.web_name,
       ss.store_sales_total,
       ws.web_sales_total,
       ss.genders_array AS store_genders,
       ws.genders_array AS web_genders
   FROM store_sales_agg ss
   FULL OUTER JOIN web_sales_agg ws
       ON ss.d_date = ws.d_date
          AND ss.s_store_name = ws.web_name
)
SELECT *
FROM (
   SELECT DISTINCT
       fj.sale_date,
       g AS gender
   FROM full_join fj
   CROSS JOIN UNNEST(fj.store_genders) AS t(g)
   WHERE fj.store_sales_total > (
         SELECT MAX(ss_ext_sales_price) FROM store_sales
   )
) 
INTERSECT
SELECT *
FROM (
   SELECT DISTINCT
       d.d_date AS sale_date,
       cd.cd_gender AS gender
   FROM web_returns wr
   JOIN date_dim d       ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN customer c       ON wr.wr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year = 2002
)
ORDER BY sale_date DESC, gender
LIMIT 100
