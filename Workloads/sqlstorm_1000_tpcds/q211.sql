WITH sales_union AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_net_profit AS net_profit,
           cs.cs_order_number AS order_number,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2001

    UNION ALL

    SELECT ss.ss_customer_sk AS customer_sk,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_net_profit AS net_profit,
           ss.ss_ticket_number AS order_number,
           'store' AS channel
    FROM store_sales ss
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001

    UNION ALL

    SELECT ws.ws_bill_customer_sk AS customer_sk,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_net_profit AS net_profit,
           ws.ws_order_number AS order_number,
           'web' AS channel
    FROM web_sales ws
    JOIN date_dim d3 ON ws.ws_sold_date_sk = d3.d_date_sk
    WHERE d3.d_year = 2001
),
agg_by_customer AS (
    SELECT customer_sk,
           SUM(net_profit) AS total_net_profit,
           COUNT(*) AS transaction_count,
           MAX(net_profit) AS max_single_tx_profit,
           MIN(date_sk) AS first_purchase_date_sk
    FROM sales_union
    GROUP BY customer_sk
),
channel_presence AS (
    SELECT customer_sk,
           MAX(CASE WHEN channel = 'store' THEN 1 ELSE 0 END) AS has_store,
           MAX(CASE WHEN channel = 'web' THEN 1 ELSE 0 END) AS has_web,
           MAX(CASE WHEN channel = 'catalog' THEN 1 ELSE 0 END) AS has_catalog
    FROM sales_union
    GROUP BY customer_sk
),
top_order AS (
    SELECT customer_sk,
           order_number,
           channel,
           net_profit
    FROM (
        SELECT su.customer_sk,
               su.order_number,
               su.channel,
               su.net_profit,
               ROW_NUMBER() OVER (PARTITION BY su.customer_sk ORDER BY su.net_profit DESC) AS rn
        FROM sales_union su
    ) t
    WHERE rn = 1
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        concat_ws(' ', c.c_first_name, c.c_last_name) AS full_name,
        c.c_email_address,
        ca.ca_city,
        ca.ca_state,
        COALESCE(c.c_birth_year, 1900) AS birth_year,
        a.total_net_profit,
        a.transaction_count,
        a.max_single_tx_profit,
        a.first_purchase_date_sk,
        d_first.d_date AS first_purchase_date,
        cp.has_store,
        cp.has_web,
        cp.has_catalog,
        CASE 
            WHEN a.total_net_profit > 100000 THEN 'Platinum'
            WHEN a.total_net_profit > 50000 THEN 'Gold'
            ELSE 'Silver'
        END AS tier
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN agg_by_customer a ON c.c_customer_sk = a.customer_sk
    LEFT JOIN channel_presence cp ON c.c_customer_sk = cp.customer_sk
    LEFT JOIN date_dim d_first ON a.first_purchase_date_sk = d_first.d_date_sk
    WHERE c.c_email_address IS NOT NULL
      AND (REGEXP_LIKE(concat_ws(' ', c.c_first_name, c.c_last_name), '^A')
           OR REGEXP_LIKE(concat_ws(' ', c.c_first_name, c.c_last_name), 'z$'))
)
SELECT 
    ci.full_name,
    ci.tier,
    ci.c_email_address,
    ci.ca_city,
    ci.ca_state,
    ci.birth_year,
    ROUND(ci.total_net_profit, 2) AS total_net_profit,
    ROW_NUMBER() OVER (ORDER BY ci.total_net_profit DESC) AS profit_rank,
    ci.transaction_count,
    ROUND(ci.max_single_tx_profit, 2) AS max_single_tx_profit,
    ci.first_purchase_date,
    CASE 
        WHEN ci.has_store = 1 AND ci.has_web = 1 THEN 'Omni-Channel'
        WHEN ci.has_store = 1 THEN 'Store Only'
        WHEN ci.has_web = 1 THEN 'Web Only'
        ELSE 'Other'
    END AS channel_profile,
    top.order_number AS top_order_number,
    top.channel AS top_order_channel,
    ROUND(top.net_profit, 2) AS top_order_profit,
    (
        SELECT COALESCE(SUM(su.net_profit), 0)
        FROM sales_union su
        WHERE su.customer_sk = ci.c_customer_sk
          AND su.channel <> 'catalog'
    ) AS other_channel_profit,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM sales_union su
            WHERE su.customer_sk = ci.c_customer_sk AND su.channel = 'store'
        )
        AND EXISTS (
            SELECT 1 FROM sales_union su
            WHERE su.customer_sk = ci.c_customer_sk AND su.channel = 'web'
        )
        THEN 'Yes' ELSE 'No' END AS both_store_and_web
FROM customer_info ci
LEFT JOIN top_order top ON ci.c_customer_sk = top.customer_sk
WHERE ci.tier IN ('Platinum','Gold')
ORDER BY ci.total_net_profit DESC
LIMIT 100
