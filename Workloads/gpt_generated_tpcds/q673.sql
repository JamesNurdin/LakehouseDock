WITH catalog_sales_agg AS (
    SELECT c.c_customer_sk,
           SUM(cs.cs_net_paid) AS total_catalog_sales
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
store_sales_agg AS (
    SELECT c.c_customer_sk,
           SUM(ss.ss_net_paid) AS total_store_sales
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
catalog_returns_agg AS (
    SELECT c.c_customer_sk,
           SUM(cr.cr_net_loss) AS total_catalog_returns
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_item_sk = cs.cs_item_sk
                         AND cr.cr_order_number = cs.cs_order_number
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
store_returns_agg AS (
    SELECT c.c_customer_sk,
           SUM(sr.sr_net_loss) AS total_store_returns
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
web_returns_agg AS (
    SELECT c.c_customer_sk,
           SUM(wr.wr_net_loss) AS total_web_returns
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
sales_total AS (
    SELECT COALESCE(cs.c_customer_sk, ss.c_customer_sk) AS c_customer_sk,
           COALESCE(cs.total_catalog_sales, 0) + COALESCE(ss.total_store_sales, 0) AS total_sales
    FROM catalog_sales_agg cs
    FULL OUTER JOIN store_sales_agg ss ON cs.c_customer_sk = ss.c_customer_sk
),
returns_total AS (
    SELECT COALESCE(cr.c_customer_sk, sr.c_customer_sk, wr.c_customer_sk) AS c_customer_sk,
           COALESCE(cr.total_catalog_returns, 0)
         + COALESCE(sr.total_store_returns, 0)
         + COALESCE(wr.total_web_returns, 0) AS total_returns_loss
    FROM catalog_returns_agg cr
    FULL OUTER JOIN store_returns_agg sr ON cr.c_customer_sk = sr.c_customer_sk
    FULL OUTER JOIN web_returns_agg wr ON COALESCE(cr.c_customer_sk, sr.c_customer_sk) = wr.c_customer_sk
),
customer_summary AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           COALESCE(st.total_sales, 0) AS total_sales,
           COALESCE(rt.total_returns_loss, 0) AS total_returns_loss,
           COALESCE(st.total_sales, 0) - COALESCE(rt.total_returns_loss, 0) AS net_profit
    FROM customer c
    LEFT JOIN sales_total st ON c.c_customer_sk = st.c_customer_sk
    LEFT JOIN returns_total rt ON c.c_customer_sk = rt.c_customer_sk
)
SELECT cs.c_customer_id,
       cs.total_sales,
       cs.total_returns_loss,
       cs.net_profit
FROM customer_summary cs
WHERE cs.net_profit > 0
ORDER BY cs.net_profit DESC
LIMIT 100
