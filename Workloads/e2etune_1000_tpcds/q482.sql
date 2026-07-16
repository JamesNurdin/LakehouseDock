WITH offline_sales AS (
    SELECT
        ca.ca_county AS county,
        s.s_store_name,
        s.s_market_desc,
        SUM(ss.ss_net_paid) AS offline_net_paid,
        SUM(ss.ss_net_profit) AS offline_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS offline_transactions,
        CASE 
            WHEN SUM(ss.ss_net_paid) = 0 THEN 0
            ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_net_paid)
        END AS offline_profit_margin
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_state = 'CA'
      AND s.s_state = 'CA'
      AND ca.ca_location_type = 'single family'
    GROUP BY ca.ca_county, s.s_store_name, s.s_market_desc
),
online_sales AS (
    SELECT
        ca.ca_county AS county,
        wp.wp_type,
        SUM(ws.ws_net_paid) AS online_net_paid,
        SUM(ws.ws_net_profit) AS online_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS online_transactions,
        CASE 
            WHEN SUM(ws.ws_net_paid) = 0 THEN 0
            ELSE SUM(ws.ws_net_profit) / SUM(ws.ws_net_paid)
        END AS online_profit_margin
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_state = 'CA'
      AND wp.wp_type = 'product'
    GROUP BY ca.ca_county, wp.wp_type
)
SELECT
    COALESCE(off.county, onl.county) AS county,
    off.s_store_name,
    off.s_market_desc,
    off.offline_net_paid,
    off.offline_net_profit,
    off.offline_profit_margin,
    onl.online_net_paid,
    onl.online_net_profit,
    onl.online_profit_margin,
    (COALESCE(off.offline_net_profit, 0) + COALESCE(onl.online_net_profit, 0)) AS total_net_profit,
    RANK() OVER (ORDER BY (COALESCE(off.offline_net_profit, 0) + COALESCE(onl.online_net_profit, 0)) DESC) AS profit_rank
FROM offline_sales off
FULL OUTER JOIN online_sales onl
    ON off.county = onl.county
WHERE (COALESCE(off.offline_net_paid, 0) > 50000 OR COALESCE(onl.online_net_paid, 0) > 50000)
ORDER BY total_net_profit DESC
LIMIT 100
