WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
)
SELECT item_sk,
       ship_mode,
       url_part,
       total_sales
FROM (
    SELECT ws.ws_item_sk AS item_sk,
           sm.sm_type AS ship_mode,
           part AS url_part,
           (
               SELECT SUM(cs.cs_net_paid)
               FROM catalog_sales cs
               WHERE cs.cs_item_sk = ws.ws_item_sk
           ) AS total_sales
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN recent_dates rd ON ws.ws_sold_date_sk = rd.d_date_sk
    CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS t(part)
) sub_web
EXCEPT
SELECT item_sk,
       ship_mode,
       url_part,
       total_sales
FROM (
    SELECT cs.cs_item_sk AS item_sk,
           sm.sm_type AS ship_mode,
           CAST(NULL AS varchar) AS url_part,
           SUM(cs.cs_net_paid) AS total_sales
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN recent_dates rd ON cs.cs_sold_date_sk = rd.d_date_sk
    GROUP BY cs.cs_item_sk, sm.sm_type
) sub_cat
ORDER BY total_sales DESC
LIMIT 100
