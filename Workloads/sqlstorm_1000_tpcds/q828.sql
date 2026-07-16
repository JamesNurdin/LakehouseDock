WITH
store_profit AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        d.d_year,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(*) AS orders,
        MAX(d.d_date) AS latest_date
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_customer_sk, d.d_year
),
catalog_profit AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        d.d_year,
        SUM(cs.cs_net_profit) AS net_profit,
        COUNT(*) AS orders,
        MAX(d.d_date) AS latest_date
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_bill_customer_sk, d.d_year
),
web_profit AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        d.d_year,
        SUM(ws.ws_net_profit) AS net_profit,
        COUNT(*) AS orders,
        MAX(d.d_date) AS latest_date
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_bill_customer_sk, d.d_year
),
combined_profit AS (
    SELECT * FROM store_profit
    UNION ALL
    SELECT * FROM catalog_profit
    UNION ALL
    SELECT * FROM web_profit
),
agg_profit AS (
    SELECT
        cp.customer_sk,
        SUM(cp.net_profit) AS total_net_profit,
        SUM(cp.orders) AS total_orders,
        MAX(cp.latest_date) AS most_recent_purchase
    FROM combined_profit cp
    GROUP BY cp.customer_sk
),
cross_channel_customers AS (
    SELECT ss.ss_customer_sk AS customer_sk FROM store_sales ss
    INTERSECT
    SELECT cs.cs_bill_customer_sk FROM catalog_sales cs
    INTERSECT
    SELECT ws.ws_bill_customer_sk FROM web_sales ws
),
customer_details AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        COALESCE(c.c_first_name, '') AS first_name,
        COALESCE(c.c_last_name, '') AS last_name,
        CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        COALESCE(ca.ca_state, 'UNKNOWN') AS state,
        CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS cust_type,
        ap.total_net_profit,
        ap.total_orders,
        ap.most_recent_purchase,
        (SELECT MAX(ws2.ws_sales_price) FROM web_sales ws2 WHERE ws2.ws_bill_customer_sk = c.c_customer_sk) AS max_web_sales_price,
        (SELECT COUNT(DISTINCT ss2.ss_store_sk) FROM store_sales ss2 WHERE ss2.ss_customer_sk = c.c_customer_sk) AS distinct_stores_visited,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(ca.ca_state, 'UNKNOWN') ORDER BY ap.total_net_profit DESC) AS state_rank
    FROM customer c
    LEFT JOIN agg_profit ap ON c.c_customer_sk = ap.customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    INNER JOIN cross_channel_customers cc ON c.c_customer_sk = cc.customer_sk
    WHERE ap.total_net_profit IS NOT NULL
)
SELECT
    cd.customer_sk,
    cd.full_name,
    cd.gender,
    cd.buy_potential,
    cd.cust_type,
    cd.state,
    cd.state_rank,
    cd.total_orders,
    cd.total_net_profit,
    ROUND(cd.total_net_profit / NULLIF(cd.total_orders, 0), 2) AS profit_per_order,
    cd.most_recent_purchase,
    cd.max_web_sales_price,
    cd.distinct_stores_visited
FROM customer_details cd
WHERE cd.total_net_profit > 0
  AND cd.buy_potential = 'HIGH'
  AND cd.state_rank <= 5
  AND cd.max_web_sales_price > 100
ORDER BY cd.total_net_profit DESC
LIMIT 100
