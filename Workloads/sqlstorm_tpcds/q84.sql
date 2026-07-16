WITH all_sales AS (
    SELECT ss_sold_date_sk AS sold_date_sk,
           ss_item_sk AS item_sk,
           ss_store_sk AS channel_id,
           'Store' AS channel,
           ss_quantity AS quantity,
           ss_net_paid AS net_paid,
           ss_net_profit AS net_profit
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_call_center_sk,
           'Catalog',
           cs_quantity,
           cs_net_paid,
           cs_net_profit
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_web_page_sk,
           'Web',
           ws_quantity,
           ws_net_paid,
           ws_net_profit
    FROM web_sales
),
sales_agg AS (
    SELECT a.item_sk,
           d.d_year AS sold_year,
           a.channel,
           SUM(a.quantity) AS total_qty,
           SUM(a.net_paid) AS total_net_paid,
           SUM(a.net_profit) AS total_net_profit,
           CASE WHEN SUM(a.net_paid) = 0 THEN NULL
                ELSE SUM(a.net_profit) / SUM(a.net_paid) END AS profit_margin
    FROM all_sales a
    JOIN date_dim d ON a.sold_date_sk = d.d_date_sk
    GROUP BY a.item_sk, d.d_year, a.channel
),
ranked_items AS (
    SELECT s.*,
           ROW_NUMBER() OVER (PARTITION BY s.sold_year, s.channel ORDER BY s.total_net_profit DESC) AS profit_rank,
           LAG(s.total_net_profit) OVER (PARTITION BY s.sold_year, s.channel ORDER BY s.total_net_profit DESC) AS prev_year_profit
    FROM sales_agg s
),
item_info AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_brand,
           COALESCE(i.i_color, 'UNKNOWN') AS color,
           CONCAT(i.i_brand, ' ', i.i_product_name) AS full_name
    FROM item i
),
customer_spending AS (
    SELECT ss.ss_customer_sk AS customer_sk,
           d.d_year AS year,
           SUM(ss.ss_net_paid) AS total_spent,
           COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
           CASE WHEN SUM(ss.ss_net_paid) > 10000 THEN 'Gold'
                WHEN SUM(ss.ss_net_paid) > 5000 THEN 'Silver'
                ELSE 'Bronze' END AS tier
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_customer_sk, d.d_year
),
top_customers AS (
    SELECT cs.customer_sk,
           cs.year,
           cs.total_spent,
           cs.tier,
           ROW_NUMBER() OVER (PARTITION BY cs.year ORDER BY cs.total_spent DESC) AS cust_rank
    FROM customer_spending cs
    WHERE cs.total_spent > 0
),
recent_returns AS (
    SELECT r.item_sk,
           r.sold_year,
           'Y' AS recent_return_flag
    FROM (
        SELECT cr.cr_item_sk AS item_sk,
               d.d_year AS sold_year,
               d.d_date AS return_date
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        UNION ALL
        SELECT sr.sr_item_sk,
               d.d_year,
               d.d_date
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        UNION ALL
        SELECT wr.wr_item_sk,
               d.d_year,
               d.d_date
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    ) r
    GROUP BY r.item_sk, r.sold_year
)
SELECT
    ri.sold_year,
    ri.channel,
    ri.item_sk,
    ii.full_name,
    ii.i_brand AS brand,
    ri.total_qty,
    CAST(ri.total_net_paid AS DOUBLE) AS total_net_paid,
    CAST(ri.total_net_profit AS DOUBLE) AS total_net_profit,
    ROUND(ri.profit_margin, 4) AS profit_margin,
    ri.profit_rank,
    COALESCE(ri.prev_year_profit, 0) AS prev_year_profit,
    CASE
        WHEN ri.profit_margin >= 0.2 THEN 'HIGH'
        WHEN ri.profit_margin >= 0.1 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    tc.cust_rank AS top_customer_rank,
    tc.tier AS customer_tier,
    COALESCE(c.c_preferred_cust_flag, 'N') AS pref_cust_flag,
    COALESCE(cd.cd_gender, 'U') AS gender,
    COALESCE(ca.ca_state, 'UNKNOWN') AS state,
    COALESCE(rr.recent_return_flag, 'N') AS recent_return_flag
FROM ranked_items ri
LEFT JOIN item_info ii ON ri.item_sk = ii.i_item_sk
LEFT JOIN top_customers tc ON ri.sold_year = tc.year AND tc.cust_rank = 1
LEFT JOIN customer c ON tc.customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN recent_returns rr ON ri.item_sk = rr.item_sk AND ri.sold_year = rr.sold_year
WHERE ri.profit_rank <= 5

UNION ALL

SELECT
    NULL AS sold_year,
    NULL AS channel,
    ii.i_item_sk AS item_sk,
    ii.full_name,
    ii.i_brand AS brand,
    NULL AS total_qty,
    NULL AS total_net_paid,
    NULL AS total_net_profit,
    NULL AS profit_margin,
    NULL AS profit_rank,
    NULL AS prev_year_profit,
    'NO_SALES' AS profit_category,
    NULL AS top_customer_rank,
    NULL AS customer_tier,
    NULL AS pref_cust_flag,
    NULL AS gender,
    NULL AS state,
    COALESCE(rr.recent_return_flag, 'N') AS recent_return_flag
FROM item_info ii
LEFT JOIN recent_returns rr ON ii.i_item_sk = rr.item_sk
WHERE NOT EXISTS (
    SELECT 1 FROM ranked_items ri WHERE ri.item_sk = ii.i_item_sk AND ri.profit_rank <= 5
)
ORDER BY sold_year DESC NULLS LAST, channel, profit_rank
LIMIT 200
