WITH store_data AS (
    SELECT s.s_state AS state,
           d.d_year AS year,
           ss.ss_net_profit AS net_profit,
           ss.ss_net_paid AS net_paid,
           ss.ss_customer_sk AS cust_sk,
           ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
),
catalog_data AS (
    SELECT cc.cc_state AS state,
           d.d_year AS year,
           cs.cs_net_profit AS net_profit,
           cs.cs_net_paid AS net_paid,
           cs.cs_bill_customer_sk AS cust_sk,
           cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
),
web_data AS (
    SELECT w.web_state AS state,
           d.d_year AS year,
           ws.ws_net_profit AS net_profit,
           ws.ws_net_paid AS net_paid,
           ws.ws_bill_customer_sk AS cust_sk,
           ws.ws_item_sk AS item_sk
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT state,
       year,
       total_net_profit,
       total_net_paid,
       uniq_customers,
       uniq_items,
       total_transactions,
       RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT state,
           year,
           SUM(net_profit) AS total_net_profit,
           SUM(net_paid) AS total_net_paid,
           COUNT(DISTINCT cust_sk) AS uniq_customers,
           COUNT(DISTINCT item_sk) AS uniq_items,
           COUNT(*) AS total_transactions
    FROM (
        SELECT * FROM store_data
        UNION ALL
        SELECT * FROM catalog_data
        UNION ALL
        SELECT * FROM web_data
    ) all_sales
    GROUP BY state, year
) agg
ORDER BY total_net_profit DESC
LIMIT 100
