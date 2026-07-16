WITH max_year AS (
    SELECT MAX(d_year) AS yr FROM date_dim
),
catalog_cust AS (
    SELECT DISTINCT cs.cs_bill_customer_sk AS cust_id
    FROM catalog_sales cs
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = (SELECT yr FROM max_year)
),
store_cust AS (
    SELECT DISTINCT ss.ss_customer_sk AS cust_id
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = (SELECT yr FROM max_year)
),
web_cust AS (
    SELECT DISTINCT ws.ws_bill_customer_sk AS cust_id
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = (SELECT yr FROM max_year)
),
multi_channel_cust AS (
    SELECT cust_id FROM catalog_cust
    INTERSECT
    SELECT cust_id FROM store_cust
    INTERSECT
    SELECT cust_id FROM web_cust
),
sales_union AS (
    SELECT cs.cs_bill_customer_sk AS cust_id, cs.cs_sold_date_sk AS date_sk, cs.cs_net_profit AS net_profit, cs.cs_quantity AS qty
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_customer_sk, ss.ss_sold_date_sk, ss.ss_net_profit, ss.ss_quantity
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_bill_customer_sk, ws.ws_sold_date_sk, ws.ws_net_profit, ws.ws_quantity
    FROM web_sales ws
),
customer_facts AS (
    SELECT
        c.c_customer_sk AS cust_id,
        SUM(s.net_profit) AS total_profit,
        SUM(s.qty) AS total_qty,
        COALESCE(ca.ca_city, 'UNKNOWN') AS city,
        COALESCE(ca.ca_state, 'UNKNOWN') AS state,
        CONCAT_WS(' ', c.c_first_name, c.c_last_name) AS full_name
    FROM sales_union s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN max_year my ON d.d_year = my.yr
    JOIN customer c ON s.cust_id = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
),
ranked_customers AS (
    SELECT
        cf.*,
        ROW_NUMBER() OVER (PARTITION BY cf.state ORDER BY cf.total_profit DESC) AS state_rank,
        CASE
            WHEN cf.total_profit > (
                SELECT AVG(total_profit)
                FROM customer_facts cf2
                WHERE cf2.state = cf.state
            )
            THEN 'AboveAvg' ELSE 'BelowAvg'
        END AS profit_vs_state_avg
    FROM customer_facts cf
    WHERE cf.cust_id IN (SELECT cust_id FROM multi_channel_cust)
)
SELECT
    rc.cust_id,
    rc.full_name,
    rc.city,
    rc.state,
    rc.total_profit,
    rc.total_qty,
    rc.total_profit / NULLIF(rc.total_qty, 0) AS avg_profit_per_item,
    rc.state_rank,
    rc.profit_vs_state_avg,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM catalog_sales cs
            WHERE cs.cs_bill_customer_sk = rc.cust_id
              AND cs.cs_sold_date_sk = (
                  SELECT MIN(d_date_sk)
                  FROM date_dim
                  WHERE d_year = (SELECT yr FROM max_year)
              )
        ) THEN 'FirstCatalog' ELSE NULL
    END AS first_catalog_purchase_date_flag
FROM ranked_customers rc
WHERE rc.state_rank <= 5
ORDER BY rc.state, rc.state_rank
