WITH
sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_education_status,
        ca.ca_state,
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE
        cd.cd_gender = 'M'
        AND cd.cd_education_status = 'College'
        AND ca.ca_state IN ('AK', 'NM', 'MS')
        AND wp.wp_type = 'home'
        AND wsite.web_street_type = 'Avenue'
        AND wsite.web_city = 'Seattle'
        AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451170
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_education_status,
        ca.ca_state,
        ws.ws_web_site_sk,
        ws.ws_web_page_sk
),
returns_agg AS (
    SELECT
        c.c_customer_sk,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(sr.sr_net_loss) AS total_loss
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE
        cd.cd_gender = 'M'
        AND cd.cd_education_status = 'College'
        AND ca.ca_state = 'AK'
        AND sr.sr_return_quantity > 0
        AND sr.sr_return_amt > 0
    GROUP BY
        c.c_customer_sk
),
profitable_customers AS (
    SELECT
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_sales,
        s.total_profit,
        COALESCE(r.total_loss, 0) AS total_loss,
        (s.total_profit - COALESCE(r.total_loss, 0)) AS net_profit_after_returns
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.c_customer_sk = r.c_customer_sk
    WHERE
        (s.total_profit - COALESCE(r.total_loss, 0)) > 1000
        AND NOT EXISTS (
            SELECT 1
            FROM store_returns sr_ex
            WHERE sr_ex.sr_customer_sk = s.c_customer_sk
              AND sr_ex.sr_reason_sk = 2
        )
),
high_profit_customers AS (
    SELECT c_customer_sk
    FROM profitable_customers
    WHERE net_profit_after_returns > 5000
),
frequent_customers AS (
    SELECT c_customer_sk
    FROM sales_agg
    WHERE num_orders >= 5
),
union_customers AS (
    SELECT c_customer_sk FROM high_profit_customers
    UNION ALL
    SELECT c_customer_sk FROM frequent_customers
),
home_page_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM web_sales ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE wp.wp_type = 'home'
),
product_page_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM web_sales ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE wp.wp_type = 'product'
),
intersect_customers AS (
    SELECT c_customer_sk FROM home_page_customers
    INTERSECT
    SELECT c_customer_sk FROM product_page_customers
),
final_agg AS (
    SELECT
        pc.c_customer_sk,
        pc.c_first_name,
        pc.c_last_name,
        pc.total_sales,
        pc.total_profit,
        pc.total_loss,
        pc.net_profit_after_returns
    FROM profitable_customers pc
    JOIN union_customers uc
        ON pc.c_customer_sk = uc.c_customer_sk
    JOIN intersect_customers ic
        ON pc.c_customer_sk = ic.c_customer_sk
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    total_sales,
    total_profit,
    total_loss,
    net_profit_after_returns
FROM final_agg
ORDER BY net_profit_after_returns DESC
LIMIT 100
