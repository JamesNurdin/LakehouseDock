WITH year_2001_bounds AS (
    SELECT MIN(d_date_sk) AS min_sk, MAX(d_date_sk) AS max_sk
    FROM date_dim
    WHERE d_year = 2001
),

sales_agg AS (
    SELECT ca.ca_state AS state,
           SUM(ss.ss_net_profit) AS net_profit,
           AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN year_2001_bounds yb ON d.d_date_sk BETWEEN yb.min_sk AND yb.max_sk
    GROUP BY ca.ca_state
),

web_sales_agg AS (
    SELECT ca.ca_state AS state,
           SUM(ws.ws_net_profit) AS net_profit,
           AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN year_2001_bounds yb ON d.d_date_sk BETWEEN yb.min_sk AND yb.max_sk
    GROUP BY ca.ca_state
),

combined_sales AS (
    SELECT state,
           SUM(net_profit) AS total_net_profit,
           AVG(avg_discount) AS avg_discount
    FROM (
        SELECT state, net_profit, avg_discount FROM sales_agg
        UNION ALL
        SELECT state, net_profit, avg_discount FROM web_sales_agg
    ) s
    GROUP BY state
),

call_center_tax AS (
    SELECT cc.cc_state AS state,
           AVG(cc.cc_tax_percentage) AS avg_tax_percentage
    FROM call_center cc
    JOIN year_2001_bounds yb ON cc.cc_open_date_sk <= yb.max_sk
    LEFT JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
    WHERE cc.cc_closed_date_sk IS NULL OR d_closed.d_date_sk >= yb.min_sk
    GROUP BY cc.cc_state
)
SELECT cs.state,
       cs.total_net_profit,
       cs.avg_discount,
       cct.avg_tax_percentage
FROM combined_sales cs
LEFT JOIN call_center_tax cct ON cs.state = cct.state
WHERE cs.total_net_profit > 0
ORDER BY cs.total_net_profit DESC
LIMIT 20
