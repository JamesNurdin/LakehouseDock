WITH sub_sales_sample AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),
first_part AS (
    SELECT
        ss.ss_ticket_number,
        d.d_year,
        ca.ca_state AS location,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS rn
    FROM sub_sales_sample ss
    FULL OUTER JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_ticket_number NOT IN (
        SELECT ss2.ss_ticket_number FROM store_sales ss2 WHERE ss2.ss_quantity > 90
    )
      AND d.d_year = 2002
    GROUP BY ss.ss_ticket_number, d.d_year, ca.ca_state
    HAVING SUM(ss.ss_net_paid_inc_tax) > 1000
),
second_part AS (
    SELECT
        ss2.ss_ticket_number,
        d2.d_year,
        ws.web_city AS location,
        SUM(ss2.ss_net_paid_inc_tax) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_city ORDER BY SUM(ss2.ss_net_paid_inc_tax) DESC) AS rn
    FROM store_sales ss2
    JOIN date_dim d2
        ON ss2.ss_sold_date_sk = d2.d_date_sk
    FULL OUTER JOIN web_site ws
        ON ws.web_open_date_sk = d2.d_date_sk
    WHERE ss2.ss_ticket_number NOT IN (
        SELECT ss3.ss_ticket_number FROM store_sales ss3 WHERE ss3.ss_quantity > 90
    )
      AND ws.web_city LIKE 'Mount%'
    GROUP BY ss2.ss_ticket_number, d2.d_year, ws.web_city
    HAVING SUM(ss2.ss_net_paid_inc_tax) > 500
)
SELECT *
FROM (
    SELECT ss_ticket_number, d_year, location, total_net_paid, rn FROM first_part
    UNION
    SELECT ss_ticket_number, d_year, location, total_net_paid, rn FROM second_part
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
