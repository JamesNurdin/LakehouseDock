WITH catalog_sales_agg AS (
    SELECT w.w_state AS state,
           i.i_category AS category,
           d.d_year AS year,
           SUM(cs.cs_net_profit) AS net_profit,
           SUM(cs.cs_net_paid) AS net_paid,
           SUM(cs.cs_quantity) AS quantity,
           COUNT(DISTINCT cs.cs_bill_customer_sk) AS cust_count
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY w.w_state, i.i_category, d.d_year
),
store_sales_agg AS (
    SELECT s.s_state AS state,
           i.i_category AS category,
           d.d_year AS year,
           SUM(ss.ss_net_profit) AS net_profit,
           SUM(ss.ss_net_paid) AS net_paid,
           SUM(ss.ss_quantity) AS quantity,
           COUNT(DISTINCT ss.ss_customer_sk) AS cust_count
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_state, i.i_category, d.d_year
),
web_sales_agg AS (
    SELECT we.web_state AS state,
           i.i_category AS category,
           d.d_year AS year,
           SUM(ws.ws_net_profit) AS net_profit,
           SUM(ws.ws_net_paid) AS net_paid,
           SUM(ws.ws_quantity) AS quantity,
           COUNT(DISTINCT ws.ws_bill_customer_sk) AS cust_count
    FROM web_sales ws
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY we.web_state, i.i_category, d.d_year
),
combined_sales AS (
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
agg_sales AS (
    SELECT state,
           category,
           year,
           SUM(net_profit) AS total_net_profit,
           SUM(net_paid) AS total_net_paid,
           SUM(quantity) AS total_quantity,
           SUM(cust_count) AS total_cust_count
    FROM combined_sales
    GROUP BY state, category, year
),
ranked_sales AS (
    SELECT state,
           category,
           year,
           total_net_profit,
           total_net_paid,
           total_quantity,
           total_cust_count,
           ROW_NUMBER() OVER (PARTITION BY state, year ORDER BY total_net_profit DESC) AS profit_rank,
           SUM(total_net_profit) OVER (PARTITION BY state ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
           LAG(total_net_profit) OVER (PARTITION BY state, category ORDER BY year) AS prev_year_profit,
           CASE WHEN LAG(total_net_profit) OVER (PARTITION BY state, category ORDER BY year) IS NOT NULL
                THEN (total_net_profit - LAG(total_net_profit) OVER (PARTITION BY state, category ORDER BY year))
                     / NULLIF(LAG(total_net_profit) OVER (PARTITION BY state, category ORDER BY year), 0) * 100
                ELSE NULL END AS profit_yoy_pct
    FROM agg_sales
    WHERE year BETWEEN 1998 AND 2001
)
SELECT state,
       year,
       category,
       total_net_profit,
       total_net_paid,
       total_quantity,
       total_cust_count,
       profit_rank,
       cumulative_profit,
       profit_yoy_pct
FROM ranked_sales
WHERE profit_rank <= 5
ORDER BY state, year, profit_rank
