SELECT category,
       source,
       total_amount
FROM (
   SELECT i.i_category AS category,
          'RETURN' AS source,
          SUM(cr.cr_return_amount) AS total_amount
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE d.d_year = 2001
     AND cp.cp_type = 'monthly'
   GROUP BY i.i_category
   UNION ALL
   SELECT i.i_category AS category,
          'SALES' AS source,
          SUM(ws.ws_ext_sales_price) AS total_amount
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year = 2001
     AND wp.wp_type = 'home'
   GROUP BY i.i_category
) t
ORDER BY category,
         source
