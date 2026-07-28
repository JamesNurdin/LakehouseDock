WITH store_profit AS (
    SELECT
        s.s_state AS region,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(c.c_email_address, '^.*@example\\.com$')
      AND c.c_first_name LIKE 'A%'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_customer_sk = c.c_customer_sk
            AND sr.sr_net_loss > 1000
      )
    GROUP BY s.s_state
),
web_profit AS (
    SELECT
        ws_site.web_state AS region,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(wp.wp_url, 'promo|discount')
      AND substring(c.c_last_name, 1, 1) = 'S'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_customer_sk = c.c_customer_sk
            AND sr.sr_net_loss > 1000
      )
    GROUP BY ws_site.web_state
)
SELECT DISTINCT
    combined.region,
    combined.total_profit,
    combined.metric,
    CONCAT(combined.region, ':', CAST(combined.total_profit AS VARCHAR)) AS label
FROM (
    SELECT region, total_profit, distinct_tickets AS metric
    FROM store_profit
    UNION ALL
    SELECT region, total_profit, distinct_orders AS metric
    FROM web_profit
) combined
ORDER BY combined.total_profit DESC
LIMIT 100
