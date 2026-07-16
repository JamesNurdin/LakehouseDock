WITH sales_all AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_profit AS net_profit,
           cs.cs_quantity AS quantity,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_customer_sk,
           ss.ss_item_sk,
           ss.ss_net_profit,
           ss.ss_quantity,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_bill_customer_sk,
           ws.ws_item_sk,
           ws.ws_net_profit,
           ws.ws_quantity,
           'web' AS channel
    FROM web_sales ws
),
returns_all AS (
    SELECT cr.cr_returning_customer_sk AS customer_sk,
           cr.cr_return_amt_inc_tax AS return_amount,
           cr.cr_return_tax AS return_tax,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_customer_sk,
           sr.sr_return_amt_inc_tax,
           sr.sr_return_tax,
           sr.sr_net_loss
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returning_customer_sk,
           wr.wr_return_amt_inc_tax,
           wr.wr_return_tax,
           wr.wr_net_loss
    FROM web_returns wr
),
sales_agg AS (
    SELECT s.customer_sk,
           SUM(s.net_profit) AS total_net_profit,
           SUM(s.quantity) AS total_quantity,
           COUNT(DISTINCT s.item_sk) AS distinct_items,
           array_join(array_agg(DISTINCT s.channel), ',') AS channels_used,
           MAX(s.sold_date_sk) AS latest_sold_date_sk
    FROM sales_all s
    GROUP BY s.customer_sk
),
returns_agg AS (
    SELECT r.customer_sk,
           SUM(r.return_amount) AS total_return_amount,
           SUM(r.return_tax) AS total_return_tax,
           SUM(r.net_loss) AS total_net_loss
    FROM returns_all r
    GROUP BY r.customer_sk
),
customer_base AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_email_address,
           cd.cd_gender,
           ca.ca_state,
           ca.ca_country,
           d.d_year,
           COALESCE(sa.total_net_profit, 0) AS sales_net_profit,
           COALESCE(ra.total_return_amount, 0) AS returns_amount,
           COALESCE(sa.total_quantity, 0) AS total_quantity,
           COALESCE(sa.distinct_items, 0) AS distinct_items,
           COALESCE(sa.channels_used, 'none') AS channels_used,
           sa.latest_sold_date_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN sales_agg sa ON c.c_customer_sk = sa.customer_sk
    LEFT JOIN returns_agg ra ON c.c_customer_sk = ra.customer_sk
    LEFT JOIN date_dim d ON sa.latest_sold_date_sk = d.d_date_sk
    WHERE ca.ca_country = 'United States' OR ca.ca_country IS NULL
),
customer_ranked AS (
    SELECT cb.*,
           (cb.sales_net_profit - cb.returns_amount) AS net_profit_adjusted,
           ROW_NUMBER() OVER (PARTITION BY cb.ca_state ORDER BY (cb.sales_net_profit - cb.returns_amount) DESC) AS state_rank,
           AVG(cb.sales_net_profit - cb.returns_amount) OVER (PARTITION BY cb.ca_state) AS avg_state_net_profit
    FROM customer_base cb
    WHERE cb.ca_state IS NOT NULL
),
top_customers AS (
    SELECT cr.*
    FROM customer_ranked cr
    WHERE cr.state_rank <= 5
)
SELECT
    tc.c_customer_sk,
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS full_name,
    CASE
        WHEN tc.c_email_address IS NULL THEN NULL
        ELSE REGEXP_REPLACE(tc.c_email_address, '(.{2}).+(@.+)', '\\1****\\2')
    END AS masked_email,
    COALESCE(tc.cd_gender, 'U') AS gender,
    tc.ca_state,
    tc.ca_country,
    tc.net_profit_adjusted,
    tc.total_quantity,
    tc.distinct_items,
    tc.channels_used,
    tc.d_year,
    tc.state_rank,
    tc.avg_state_net_profit,
    CASE
        WHEN tc.net_profit_adjusted > 20000 THEN 'Platinum'
        WHEN tc.net_profit_adjusted > 10000 THEN 'Gold'
        WHEN tc.net_profit_adjusted > 0 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier,
    (SELECT COUNT(*)
     FROM customer_ranked cr2
     WHERE cr2.ca_state = tc.ca_state
       AND (cr2.sales_net_profit - cr2.returns_amount) > tc.net_profit_adjusted) AS higher_profit_peers
FROM top_customers tc
ORDER BY tc.net_profit_adjusted DESC
LIMIT 100
