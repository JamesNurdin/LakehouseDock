WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        hd.hd_income_band_sk,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_store_credit,
        wp.wp_autogen_flag,
        wp.wp_max_ad_count,
        wr.wr_returning_customer_sk,
        wr.wr_return_quantity
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE c.c_birth_day IN (13, 23)
      AND hd.hd_income_band_sk > 3
      AND sr.sr_store_credit > 10
      AND wp.wp_autogen_flag = 'Y'
      AND ca.ca_street_name LIKE '%Washington%'
),
sales_agg AS (
    SELECT
        c_customer_sk,
        SUM(ss_net_paid)   AS total_paid,
        SUM(ss_net_profit) AS total_profit
    FROM base
    GROUP BY c_customer_sk
),
high_credit_customers AS (
    SELECT c_customer_sk
    FROM base
    WHERE sr_store_credit > 50
    GROUP BY c_customer_sk
    HAVING SUM(sr_store_credit) > 200
),
negative_profit_customers AS (
    SELECT c_customer_sk
    FROM base
    WHERE ss_net_profit < 0
    GROUP BY c_customer_sk
    HAVING SUM(ss_net_profit) < -1000
),
intersect_customers AS (
    SELECT c_customer_sk FROM high_credit_customers
    INTERSECT
    SELECT c_customer_sk FROM negative_profit_customers
)
SELECT
    s.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    hd.hd_income_band_sk,
    s.total_paid,
    s.total_profit
FROM sales_agg s
JOIN tpcds.customer c
    ON s.c_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN tpcds.household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE s.c_customer_sk IN (SELECT c_customer_sk FROM intersect_customers)
  AND s.c_customer_sk NOT IN (
        SELECT wr.wr_returning_customer_sk
        FROM tpcds.web_returns wr
        WHERE wr.wr_return_quantity > 10
    )
ORDER BY s.total_paid DESC
LIMIT 100
