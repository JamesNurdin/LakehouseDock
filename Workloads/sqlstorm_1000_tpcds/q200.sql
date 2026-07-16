WITH
sales_union AS (
    SELECT cs_bill_customer_sk AS customer_sk,
           cs_sold_date_sk AS date_sk,
           cs_net_paid AS net_paid,
           'catalog' AS channel,
           cs_order_number AS order_number
    FROM catalog_sales
    UNION ALL
    SELECT ss_customer_sk AS customer_sk,
           ss_sold_date_sk AS date_sk,
           ss_net_paid AS net_paid,
           'store' AS channel,
           ss_ticket_number AS order_number
    FROM store_sales
    UNION ALL
    SELECT ws_bill_customer_sk AS customer_sk,
           ws_sold_date_sk AS date_sk,
           ws_net_paid AS net_paid,
           'web' AS channel,
           ws_order_number AS order_number
    FROM web_sales
),
customer_sales AS (
    SELECT
        s.customer_sk,
        c.c_first_name,
        c.c_last_name,
        s.channel,
        SUM(s.net_paid) AS total_net_paid,
        MIN(s.date_sk) AS first_sale_date_sk,
        MAX(s.date_sk) AS last_sale_date_sk,
        COUNT(DISTINCT s.order_number) AS distinct_orders,
        ROW_NUMBER() OVER (PARTITION BY s.channel ORDER BY SUM(s.net_paid) DESC) AS channel_rank
    FROM sales_union s
    LEFT JOIN customer c ON s.customer_sk = c.c_customer_sk
    GROUP BY s.customer_sk, c.c_first_name, c.c_last_name, s.channel
),
recent_sales AS (
    SELECT
        cs.customer_sk,
        d.d_date AS recent_sale_date,
        cs.channel,
        cs.total_net_paid,
        cs.channel_rank,
        CASE
            WHEN cs.channel IS NULL THEN 'No Sales'
            WHEN cs.total_net_paid > 10000 THEN 'High Value'
            WHEN cs.total_net_paid > 5000 THEN 'Mid Value'
            ELSE 'Low Value'
        END AS sales_tier
    FROM customer_sales cs
    LEFT JOIN date_dim d ON cs.last_sale_date_sk = d.d_date_sk
),
customer_full AS (
    SELECT
        cu.c_customer_sk,
        cu.c_customer_id,
        cu.c_first_name,
        cu.c_last_name,
        d2.d_date AS birth_date,
        COALESCE(r.sales_tier, 'Never Bought') AS sales_tier,
        COALESCE(r.total_net_paid, 0) AS total_spent,
        LAG(r.total_net_paid) OVER (PARTITION BY cu.c_customer_sk ORDER BY r.recent_sale_date) AS prior_total_spent,
        CASE WHEN cu.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END AS pref_cust_flag,
        CASE WHEN CONCAT(cu.c_first_name, ' ', cu.c_last_name) IS NOT DISTINCT FROM 'John Doe' THEN TRUE ELSE FALSE END AS is_john_doe
    FROM customer cu
    LEFT JOIN recent_sales r ON cu.c_customer_sk = r.customer_sk
    LEFT JOIN date_dim d2
        ON cu.c_birth_year = EXTRACT(year FROM d2.d_date)
        AND cu.c_birth_month = EXTRACT(month FROM d2.d_date)
        AND cu.c_birth_day = EXTRACT(day FROM d2.d_date)
),
customers_in_all_channels AS (
    SELECT customer_sk FROM sales_union WHERE channel = 'catalog'
    INTERSECT
    SELECT customer_sk FROM sales_union WHERE channel = 'store'
    INTERSECT
    SELECT customer_sk FROM sales_union WHERE channel = 'web'
),
return_analysis AS (
    SELECT
        cs.customer_sk,
        SUM(COALESCE(cr.cr_refunded_cash, 0) + COALESCE(sr.sr_refunded_cash, 0) + COALESCE(wr.wr_refunded_cash, 0)) AS total_refunds,
        COUNT(DISTINCT COALESCE(cr.cr_return_quantity, 0) + COALESCE(sr.sr_return_quantity, 0) + COALESCE(wr.wr_return_quantity, 0)) AS total_return_items
    FROM sales_union cs
    LEFT JOIN catalog_returns cr ON cs.order_number = cr.cr_order_number
    FULL OUTER JOIN store_returns sr ON cs.order_number = sr.sr_ticket_number
    LEFT JOIN web_returns wr ON cs.order_number = wr.wr_order_number
    GROUP BY cs.customer_sk
)
SELECT
    cf.c_customer_id,
    cf.c_first_name,
    cf.c_last_name,
    cf.sales_tier,
    cf.total_spent,
    cf.prior_total_spent,
    cf.pref_cust_flag,
    cf.is_john_doe,
    ra.total_refunds,
    ra.total_return_items,
    CASE
        WHEN cf.sales_tier = 'High Value' AND ra.total_refunds > 0 THEN 'High risk'
        WHEN cf.sales_tier = 'Mid Value' AND ra.total_refunds > 1000 THEN 'Medium risk'
        ELSE 'Low risk'
    END AS risk_category,
    CASE
        WHEN cf.total_spent IS NULL THEN 'NoSpend'
        WHEN cf.total_spent > 0 THEN CONCAT('Spent $', CAST(cf.total_spent AS VARCHAR))
        ELSE 'ZeroSpend'
    END AS spend_label,
    (SELECT MAX(d.d_date)
     FROM store_returns sr
     JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
     WHERE sr.sr_customer_sk = cf.c_customer_sk) AS most_recent_store_return_date
FROM customer_full cf
LEFT JOIN return_analysis ra ON cf.c_customer_sk = ra.customer_sk
WHERE cf.c_customer_sk IN (SELECT customer_sk FROM customers_in_all_channels)
  AND cf.birth_date IS NOT NULL
  AND cf.birth_date BETWEEN DATE '1970-01-01' AND DATE '2000-12-31'
  AND (CASE WHEN cf.total_spent > 0 THEN 1 ELSE 0 END) = 1
ORDER BY cf.total_spent DESC NULLS LAST
LIMIT 100
