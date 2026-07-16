WITH agg AS (
    SELECT
        c.c_birth_country AS customer_birth_country,
        cp.c_salutation AS page_owner_salutation,
        wp.wp_type,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amount
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN
        customer cp ON wp.wp_customer_sk = cp.c_customer_sk
    WHERE
        c.c_birth_country IN ('IRELAND', 'CYPRUS')
        AND c.c_current_hdemo_sk = 4239
        AND wp.wp_type = 'product'
        AND ws.ws_sold_date_sk BETWEEN 2452000 AND 2452500
        AND cp.c_salutation = 'Dr.'
    GROUP BY
        c.c_birth_country,
        cp.c_salutation,
        wp.wp_type
    HAVING
        SUM(ws.ws_net_profit) > 10000
)
SELECT
    customer_birth_country,
    page_owner_salutation,
    wp_type,
    num_orders,
    num_customers,
    total_net_profit,
    avg_discount_amount,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM
    agg
ORDER BY
    total_net_profit DESC
LIMIT 10
