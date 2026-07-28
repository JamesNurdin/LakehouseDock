WITH catalog_profit AS (
   SELECT d.d_year,
          'catalog' AS channel,
          SUM(cs.cs_net_profit) AS total_profit
   FROM tpcds.catalog_sales cs
   JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   WHERE cc.cc_company = 2
     AND d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
     AND EXISTS (
         SELECT 1
         FROM tpcds.catalog_page cp
         WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
           AND cp.cp_type = 'PROMO'
     )
   GROUP BY d.d_year
),
web_profit AS (
   SELECT d.d_year,
          'web' AS channel,
          SUM(ws.ws_net_profit) AS total_profit
   FROM tpcds.web_sales ws
   JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN tpcds.web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
   WHERE wsit.web_mkt_id = 3
     AND d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
     AND EXISTS (
         SELECT 1
         FROM tpcds.web_page wp
         WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
           AND wp.wp_type = 'CONTENT'
     )
   GROUP BY d.d_year
)
SELECT *
FROM catalog_profit
UNION ALL
SELECT *
FROM web_profit
LIMIT 100
