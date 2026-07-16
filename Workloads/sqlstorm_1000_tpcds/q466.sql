WITH
sales_all AS (
    SELECT cs_bill_customer_sk AS customer_sk,
           cs_order_number AS order_number,
           cs_sold_date_sk AS sale_date_sk,
           cs_net_paid_inc_tax AS net_paid,
           cs_net_profit AS profit,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ss_customer_sk AS customer_sk,
           ss_ticket_number AS order_number,
           ss_sold_date_sk AS sale_date_sk,
           ss_net_paid_inc_tax AS net_paid,
           ss_net_profit AS profit,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_bill_customer_sk AS customer_sk,
           ws_order_number AS order_number,
           ws_sold_date_sk AS sale_date_sk,
           ws_net_paid_inc_tax AS net_paid,
           ws_net_profit AS profit,
           'web' AS channel
    FROM web_sales
    WHERE ws_net_paid_inc_tax IS NOT NULL
),
aggregated_sales AS (
    SELECT
        customer_sk,
        COUNT(*) AS total_orders,
        SUM(net_paid) AS total_net_paid,
        SUM(profit) AS total_profit,
        MAX(sale_date_sk) AS last_sale_date_sk,
        AVG(net_paid) AS avg_net_paid,
        SUM(CASE WHEN channel = 'catalog' THEN net_paid ELSE 0 END) AS catalog_net_paid,
        SUM(CASE WHEN channel = 'store' THEN net_paid ELSE 0 END) AS store_net_paid,
        SUM(CASE WHEN channel = 'web' THEN net_paid ELSE 0 END) AS web_net_paid
    FROM sales_all
    GROUP BY customer_sk
),
returns_agg AS (
    SELECT
        COALESCE(cr_returning_customer_sk, sr_customer_sk, wr_refunded_customer_sk) AS customer_sk,
        SUM(cr_return_amount) AS catalog_return_amount,
        SUM(sr_return_amt) AS store_return_amount,
        SUM(wr_return_amt) AS web_return_amount
    FROM (
        SELECT cr_returning_customer_sk,
               cr_return_amount,
               NULL AS sr_customer_sk,
               NULL AS sr_return_amt,
               NULL AS wr_refunded_customer_sk,
               NULL AS wr_return_amt
        FROM catalog_returns
        UNION ALL
        SELECT NULL,
               NULL,
               sr_customer_sk,
               sr_return_amt,
               NULL,
               NULL
        FROM store_returns
        UNION ALL
        SELECT NULL,
               NULL,
               NULL,
               NULL,
               wr_refunded_customer_sk,
               wr_return_amt
        FROM web_returns
    ) AS all_returns
    GROUP BY COALESCE(cr_returning_customer_sk, sr_customer_sk, wr_refunded_customer_sk)
),
sales_returns AS (
    SELECT
        COALESCE(a.customer_sk, r.customer_sk) AS customer_sk,
        a.total_orders,
        a.total_net_paid,
        a.total_profit,
        a.last_sale_date_sk,
        a.avg_net_paid,
        a.catalog_net_paid,
        a.store_net_paid,
        a.web_net_paid,
        r.catalog_return_amount,
        r.store_return_amount,
        r.web_return_amount
    FROM aggregated_sales a
    FULL OUTER JOIN returns_agg r ON a.customer_sk = r.customer_sk
),
customer_last_purchase AS (
    SELECT
        sr.customer_sk,
        d.d_date AS last_purchase_date
    FROM sales_returns sr
    LEFT JOIN date_dim d ON sr.last_sale_date_sk = d.d_date_sk
),
store_customers AS (
    SELECT DISTINCT customer_sk FROM sales_all WHERE channel = 'store'
),
web_customers AS (
    SELECT DISTINCT customer_sk FROM sales_all WHERE channel = 'web'
),
cross_channel_customers AS (
    SELECT customer_sk FROM store_customers INTERSECT SELECT customer_sk FROM web_customers
),
ranked_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        (CONCAT(UPPER(SUBSTR(c.c_first_name,1,1)), LOWER(SUBSTR(c.c_first_name,2))) || ' ' ||
         CONCAT(UPPER(SUBSTR(c.c_last_name,1,1)), LOWER(SUBSTR(c.c_last_name,2)))) AS full_name,
        COALESCE(cd.cd_gender, 'UNKNOWN') AS gender,
        COALESCE(ca.ca_city, 'UNKNOWN') AS city,
        COALESCE(sr.total_orders, 0) AS total_orders,
        COALESCE(sr.total_net_paid, 0.0) AS total_net_paid,
        COALESCE(sr.total_profit, 0.0) AS total_profit,
        CASE
            WHEN sr.total_net_paid > 0 THEN ROUND((sr.total_profit / sr.total_net_paid) * 100, 2)
            ELSE 0.0
        END AS profit_margin_pct,
        COALESCE(sr.catalog_return_amount, 0) + COALESCE(sr.store_return_amount, 0) + COALESCE(sr.web_return_amount, 0) AS total_returns,
        (COALESCE(sr.total_net_paid, 0.0) -
         (COALESCE(sr.catalog_return_amount, 0) + COALESCE(sr.store_return_amount, 0) + COALESCE(sr.web_return_amount, 0))) AS net_after_returns,
        clp.last_purchase_date,
        DATE_DIFF('day', clp.last_purchase_date, DATE '2024-10-01') AS days_since_last_purchase,
        ROW_NUMBER() OVER (ORDER BY sr.total_net_paid DESC NULLS LAST) AS sales_rank,
        CASE
            WHEN COALESCE(sr.total_net_paid,0) >= 20000 THEN 'PLATINUM'
            WHEN COALESCE(sr.total_net_paid,0) >= 10000 THEN 'GOLD'
            ELSE 'SILVER'
        END AS revenue_category,
        CONCAT('CUST_', CAST(c.c_customer_sk AS VARCHAR)) AS customer_key,
        REGEXP_REPLACE(c.c_email_address, '^([^@]+)@', '***@') AS masked_email,
        (SELECT MAX(s.profit) FROM sales_all s WHERE s.customer_sk = c.c_customer_sk) AS max_single_order_profit,
        (SELECT MAX(cs.cs_net_profit) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = c.c_customer_sk) AS max_catalog_profit
    FROM customer c
    LEFT JOIN sales_returns sr ON c.c_customer_sk = sr.customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_last_purchase clp ON c.c_customer_sk = clp.customer_sk
    WHERE
        (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
        AND (ca.ca_state = 'CA' OR ca.ca_state IS NULL)
        AND (sr.total_net_paid IS NULL OR sr.total_net_paid > 0)
        AND (c.c_birth_year IS NULL OR c.c_birth_year BETWEEN 1950 AND 2000)
        AND c.c_customer_sk IN (SELECT customer_sk FROM cross_channel_customers)
)
SELECT *
FROM ranked_customers
ORDER BY net_after_returns DESC, sales_rank
LIMIT 100
