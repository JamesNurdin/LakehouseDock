WITH store_agg AS (
    SELECT s.c_customer_sk,
           SUM(ss.ss_net_profit) AS store_net_profit,
           COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
           SUM(ss.ss_coupon_amt) AS store_coupon_total,
           COUNT(DISTINCT ss.ss_item_sk) AS store_distinct_items
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer s ON ss.ss_customer_sk = s.c_customer_sk
    WHERE d.d_year = 2002
    GROUP BY s.c_customer_sk
),
catalog_agg AS (
    SELECT c.c_customer_sk,
           SUM(cs.cs_net_profit) AS catalog_net_profit,
           COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
           SUM(cs.cs_coupon_amt) AS catalog_coupon_total,
           COUNT(DISTINCT cs.cs_item_sk) AS catalog_distinct_items
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
    GROUP BY c.c_customer_sk
),
web_agg AS (
    SELECT w.c_customer_sk,
           SUM(ws.ws_net_profit) AS web_net_profit,
           COUNT(DISTINCT ws.ws_order_number) AS web_orders,
           SUM(ws.ws_coupon_amt) AS web_coupon_total,
           COUNT(DISTINCT ws.ws_item_sk) AS web_distinct_items
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer w ON ws.ws_bill_customer_sk = w.c_customer_sk
    WHERE d.d_year = 2002
    GROUP BY w.c_customer_sk
),
customer_info AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_education_status,
           ca.ca_city,
           ca.ca_state
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT ci.c_customer_id,
       ci.c_first_name,
       ci.c_last_name,
       ci.cd_gender,
       ci.cd_education_status,
       ci.ca_city,
       ci.ca_state,
       COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit,
       COALESCE(s.store_orders, 0) + COALESCE(c.catalog_orders, 0) + COALESCE(w.web_orders, 0) AS total_orders,
       COALESCE(s.store_coupon_total, 0) + COALESCE(c.catalog_coupon_total, 0) + COALESCE(w.web_coupon_total, 0) AS total_coupon_amount,
       COALESCE(s.store_distinct_items, 0) + COALESCE(c.catalog_distinct_items, 0) + COALESCE(w.web_distinct_items, 0) AS total_distinct_items,
       RANK() OVER (ORDER BY COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) DESC) AS profit_rank
FROM customer_info ci
LEFT JOIN store_agg s ON ci.c_customer_sk = s.c_customer_sk
LEFT JOIN catalog_agg c ON ci.c_customer_sk = c.c_customer_sk
LEFT JOIN web_agg w ON ci.c_customer_sk = w.c_customer_sk
WHERE (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0)) > 0
ORDER BY total_net_profit DESC
LIMIT 10
