WITH store_part AS (
    SELECT
        i.i_item_id,
        d.d_date AS sales_date,
        ss.ss_net_paid AS net_paid,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND EXISTS (
          SELECT 1
          FROM customer_address ca
          WHERE ca.ca_address_sk = ss.ss_addr_sk
            AND ca.ca_state = 'CA'
      )
),
web_part AS (
    SELECT
        i.i_item_id,
        d.d_date AS sales_date,
        ws.ws_net_paid AS net_paid,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND ws.ws_net_paid > (
          SELECT avg(ws2.ws_net_paid)
          FROM web_sales ws2
          WHERE ws2.ws_item_sk = ws.ws_item_sk
      )
)
SELECT *
FROM (
    SELECT * FROM store_part
    UNION ALL
    SELECT * FROM web_part
) combined
ORDER BY net_paid DESC
LIMIT 100
