WITH
sales_combined AS (
    SELECT cs.cs_order_number AS order_number,
           cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
           cs.cs_net_profit AS net_profit,
           cs.cs_ship_mode_sk AS ship_mode_sk,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_ticket_number,
           ss.ss_sold_date_sk,
           ss.ss_customer_sk,
           ss.ss_net_paid,
           ss.ss_net_paid_inc_tax,
           ss.ss_net_profit,
           CAST(NULL AS BIGINT) AS ship_mode_sk,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_order_number,
           ws.ws_sold_date_sk,
           ws.ws_bill_customer_sk,
           ws.ws_net_paid,
           ws.ws_net_paid_inc_tax,
           ws.ws_net_profit,
           ws.ws_ship_mode_sk,
           'web' AS channel
    FROM web_sales ws
),
returns_per_order AS (
    SELECT cr.cr_order_number AS order_number,
           'catalog' AS channel,
           COUNT(*) AS ret_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_order_number
    UNION ALL
    SELECT sr.sr_ticket_number,
           'store' AS channel,
           COUNT(*) AS ret_cnt
    FROM store_returns sr
    GROUP BY sr.sr_ticket_number
    UNION ALL
    SELECT wr.wr_order_number,
           'web' AS channel,
           COUNT(*) AS ret_cnt
    FROM web_returns wr
    GROUP BY wr.wr_order_number
),
unreturned_orders AS (
    SELECT sc.order_number, sc.channel
    FROM sales_combined sc
    EXCEPT
    SELECT rpo.order_number, rpo.channel FROM returns_per_order rpo
),
customers_with_catalog_and_store AS (
    SELECT customer_sk FROM sales_combined WHERE channel='catalog'
    INTERSECT
    SELECT customer_sk FROM sales_combined WHERE channel='store'
),
cust_sales_unreturned_agg AS (
    SELECT sc.customer_sk,
           sc.channel,
           SUM(sc.net_paid) AS total_net_paid,
           SUM(sc.net_profit) AS total_net_profit,
           COUNT(*) AS order_cnt,
           MIN(sc.sold_date_sk) AS first_sold_date_sk,
           MAX(sc.sold_date_sk) AS last_sold_date_sk
    FROM sales_combined sc
    JOIN unreturned_orders uo
      ON sc.order_number = uo.order_number
     AND sc.channel = uo.channel
    GROUP BY sc.customer_sk, sc.channel
),
cust_returns_agg AS (
    SELECT sc.customer_sk,
           sc.channel,
           COALESCE(SUM(r.ret_cnt), 0) AS total_returns
    FROM sales_combined sc
    LEFT JOIN returns_per_order r
      ON sc.order_number = r.order_number
     AND sc.channel = r.channel
    GROUP BY sc.customer_sk, sc.channel
),
customer_info AS (
    SELECT c.c_customer_sk,
           CONCAT(COALESCE(c.c_salutation, ''), ' ',
                  COALESCE(c.c_first_name, ''), ' ',
                  COALESCE(c.c_last_name, '')) AS full_name,
           COALESCE(cd.cd_gender, 'U') AS cd_gender,
           COALESCE(cd.cd_marital_status, 'U') AS cd_marital_status,
           COALESCE(cd.cd_education_status, 'U') AS cd_education_status,
           COALESCE(c.c_preferred_cust_flag, 'N') AS pref_flag
    FROM customer c
    LEFT JOIN customer_demographics cd
      ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
raw_stats AS (
    SELECT ci.full_name,
           ci.pref_flag,
           ci.cd_gender,
           ci.cd_marital_status,
           ci.cd_education_status,
           csua.channel,
           csua.total_net_paid,
           csua.total_net_profit,
           csua.order_cnt,
           cr.total_returns,
           CASE
               WHEN csua.total_net_profit > 0
                AND csua.total_net_paid / NULLIF(csua.order_cnt, 0) < 100 THEN 'Y'
               ELSE 'N'
           END AS profit_flag,
           d_first.d_date AS first_sold_date,
           d_last.d_date AS last_sold_date,
           (SELECT COALESCE(SUM(sc2.net_paid), 0)
              FROM sales_combined sc2
             WHERE sc2.customer_sk = csua.customer_sk
               AND sc2.channel <> csua.channel) AS net_paid_other_channels,
           (SELECT AVG(sc3.net_paid)
              FROM sales_combined sc3
             WHERE sc3.customer_sk = csua.customer_sk
               AND sc3.sold_date_sk = csua.first_sold_date_sk) AS avg_paid_on_first_day,
           CASE WHEN cr.total_returns = 0 THEN 'No Returns' ELSE 'Has Returns' END AS return_status,
           csua.customer_sk
    FROM cust_sales_unreturned_agg csua
    LEFT JOIN cust_returns_agg cr
      ON csua.customer_sk = cr.customer_sk
     AND csua.channel = cr.channel
    JOIN customer_info ci
      ON ci.c_customer_sk = csua.customer_sk
    LEFT JOIN date_dim d_first
      ON d_first.d_date_sk = csua.first_sold_date_sk
    LEFT JOIN date_dim d_last
      ON d_last.d_date_sk = csua.last_sold_date_sk
    WHERE csua.customer_sk IN (SELECT customer_sk FROM customers_with_catalog_and_store)
),
ranked_stats AS (
    SELECT full_name,
           pref_flag,
           cd_gender,
           cd_marital_status,
           cd_education_status,
           channel,
           total_net_paid,
           total_net_profit,
           order_cnt,
           total_returns,
           profit_flag,
           first_sold_date,
           last_sold_date,
           net_paid_other_channels,
           avg_paid_on_first_day,
           return_status,
           ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_net_paid DESC NULLS LAST) AS channel_rank
    FROM raw_stats
),
top_customers AS (
    SELECT *
    FROM ranked_stats
    WHERE channel_rank <= 10
),
no_sales_customers AS (
    SELECT ci.full_name,
           ci.pref_flag,
           ci.cd_gender,
           ci.cd_marital_status,
           ci.cd_education_status,
           'N/A' AS channel,
           NULL AS total_net_paid,
           NULL AS total_net_profit,
           0 AS order_cnt,
           0 AS total_returns,
           'N' AS profit_flag,
           NULL AS first_sold_date,
           NULL AS last_sold_date,
           NULL AS net_paid_other_channels,
           NULL AS avg_paid_on_first_day,
           'No Sales' AS return_status,
           NULL AS channel_rank
    FROM customer_info ci
    WHERE NOT EXISTS (
        SELECT 1 FROM sales_combined sc
        WHERE sc.customer_sk = ci.c_customer_sk
    )
)
SELECT *
FROM top_customers
UNION ALL
SELECT *
FROM no_sales_customers
ORDER BY channel, total_net_paid DESC NULLS LAST
LIMIT 200
