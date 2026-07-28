/*
  Goal: Compare total net paid revenue for the year 2001 across the store and web channels,
  applying channel‑specific filters (store sales for a specific brand and web sales for pages
  that displayed at least one advertisement). The result shows each channel with its aggregated
  net paid amount.
*/
WITH store_chan AS (
    SELECT
        'store' AS channel,
        d.d_year AS sales_year,
        ss.ss_net_paid AS net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_brand_id = 12
),
web_chan AS (
    SELECT
        'web' AS channel,
        d.d_year AS sales_year,
        ws.ws_net_paid AS net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND wp.wp_max_ad_count > 0
)
SELECT
    t.channel,
    t.sales_year,
    SUM(t.net_paid) AS total_net_paid
FROM (
    SELECT * FROM store_chan
    UNION ALL
    SELECT * FROM web_chan
) t
GROUP BY t.channel, t.sales_year
ORDER BY t.channel
