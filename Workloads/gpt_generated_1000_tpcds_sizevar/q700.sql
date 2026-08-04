WITH sales_returns_full AS (
    SELECT
        COALESCE(ss.ss_customer_sk, sr.sr_customer_sk) AS customer_sk,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        sr.sr_net_loss
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
),
store_customer_set AS (
    SELECT DISTINCT c.c_customer_id
    FROM sales_returns_full sfr
    JOIN customer c
        ON c.c_customer_sk = sfr.customer_sk
    WHERE sfr.sr_net_loss > 0
),
web_customer_set AS (
    SELECT DISTINCT c.c_customer_id
    FROM web_sales ws
    JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    JOIN customer c
        ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE wr.wr_net_loss > 0
)
SELECT
    c.c_customer_id,
    c.c_birth_year,
    c.c_birth_country,
    ROW_NUMBER() OVER (PARTITION BY c.c_birth_country ORDER BY c.c_birth_year DESC) AS rank_in_country
FROM (
    SELECT c_customer_id FROM store_customer_set
    INTERSECT
    SELECT c_customer_id FROM web_customer_set
) AS common_customers
JOIN customer c
    ON c.c_customer_id = common_customers.c_customer_id
ORDER BY rank_in_country
LIMIT 100
