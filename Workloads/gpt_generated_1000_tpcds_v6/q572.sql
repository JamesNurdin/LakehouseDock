WITH filtered_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
)
SELECT channel,
       location,
       total_sales
FROM (
    SELECT 'Store' AS channel,
           s.s_store_name AS location,
           SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    JOIN filtered_dates fd
      ON ss.ss_sold_date_sk = fd.d_date_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_category_id = 3
    GROUP BY s.s_store_name

    UNION ALL

    SELECT 'Web' AS channel,
           w.web_name AS location,
           SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    JOIN filtered_dates fd
      ON ws.ws_sold_date_sk = fd.d_date_sk
    JOIN web_site w
      ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_category_id = 3
    GROUP BY w.web_name
) AS combined
ORDER BY total_sales DESC
LIMIT 100
