WITH
    ws_sample AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    cust_bill AS (
        SELECT
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            cd.cd_gender,
            ca.ca_state,
            c.c_current_addr_sk
        FROM customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    ),
    cust_ship AS (
        SELECT
            c.c_customer_sk AS ship_cust_sk,
            ca.ca_city AS ship_city,
            ca.ca_state AS ship_state
        FROM customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    )

SELECT
    u.ws_order_number,
    u.first_name,
    u.last_name,
    u.gender,
    u.bill_state,
    u.ship_city,
    u.ship_state,
    u.promo_name,
    u.net_paid,
    u.total_return_amount,
    u.sales_rank
FROM (
    /* ---------- first branch of the UNION ---------- */
    SELECT
        ws.ws_order_number,
        bill.c_first_name               AS first_name,
        bill.c_last_name                AS last_name,
        bill.cd_gender                  AS gender,
        bill.ca_state                   AS bill_state,
        ship.ship_city                  AS ship_city,
        ship.ship_state                 AS ship_state,
        p.p_promo_name                  AS promo_name,
        ws.ws_net_paid                  AS net_paid,
        (SELECT SUM(sr.sr_return_amt)
         FROM store_returns sr
         WHERE sr.sr_customer_sk = bill.c_customer_sk) AS total_return_amount,
        RANK() OVER (PARTITION BY bill.c_customer_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM ws_sample ws
    JOIN cust_bill bill ON ws.ws_bill_customer_sk = bill.c_customer_sk
    JOIN cust_ship ship ON ws.ws_ship_customer_sk = ship.ship_cust_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000

    UNION DISTINCT

    /* ---------- second branch of the UNION ---------- */
    SELECT
        ws.ws_order_number,
        wp_cust.c_first_name            AS first_name,
        wp_cust.c_last_name             AS last_name,
        wp_cd.cd_gender                 AS gender,
        wp_ca.ca_state                  AS bill_state,
        NULL                            AS ship_city,
        NULL                            AS ship_state,
        p.p_promo_name                  AS promo_name,
        ws.ws_net_paid                  AS net_paid,
        (SELECT SUM(sr.sr_return_amt)
         FROM store_returns sr
         WHERE sr.sr_customer_sk = wp_cust.c_customer_sk) AS total_return_amount,
        RANK() OVER (PARTITION BY wp_cust.c_customer_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM ws_sample ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer wp_cust ON wp.wp_customer_sk = wp_cust.c_customer_sk
    JOIN customer_demographics wp_cd ON wp_cust.c_current_cdemo_sk = wp_cd.cd_demo_sk
    JOIN customer_address wp_ca ON wp_cust.c_current_addr_sk = wp_ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
) AS u
INTERSECT
SELECT
    t.ws_order_number,
    t.first_name,
    t.last_name,
    t.gender,
    t.bill_state,
    t.ship_city,
    t.ship_state,
    t.promo_name,
    t.net_paid,
    t.total_return_amount,
    t.sales_rank
FROM (
    SELECT
        ws.ws_order_number,
        c.c_first_name                 AS first_name,
        c.c_last_name                  AS last_name,
        cd.cd_gender                  AS gender,
        ca.ca_state                   AS bill_state,
        ca.ca_city                    AS ship_city,
        ca.ca_state                   AS ship_state,
        p.p_promo_name                AS promo_name,
        ws.ws_net_paid                AS net_paid,
        SUM(sr.sr_return_amt) OVER (PARTITION BY c.c_customer_sk) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM ws_sample ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
) t
WHERE t.sales_rank <= 5
LIMIT 100
