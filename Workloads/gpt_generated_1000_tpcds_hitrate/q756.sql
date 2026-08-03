WITH recent_customers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_birth_year
    FROM   customer c
    WHERE  c.c_birth_year BETWEEN 1965 AND 1985
),
customer_sales AS (
    SELECT
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.c_birth_year,
        SUM(cs.cs_ext_sales_price)                                                    AS catalog_sales_amount,
        SUM(ws.ws_ext_sales_price)                                                    AS web_sales_amount,
        COUNT(DISTINCT cs.cs_order_number)                                            AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number)                                            AS web_orders,
        CASE WHEN SUM(cs.cs_ext_sales_price) > SUM(ws.ws_ext_sales_price)
             THEN 'Catalog Higher'
             ELSE 'Web Higher'
        END                                                                          AS higher_source
    FROM   recent_customers rc
    RIGHT OUTER JOIN catalog_sales cs
           ON cs.cs_bill_customer_sk = rc.c_customer_sk
    JOIN   customer_demographics cd_bill
           ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN   household_demographics hd_bill
           ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN   customer cust_ship
           ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    JOIN   customer_demographics cd_ship
           ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN   household_demographics hd_ship
           ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN   web_sales ws
           ON ws.ws_bill_customer_sk = rc.c_customer_sk
    JOIN   customer_demographics cd_ws_bill
           ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    JOIN   household_demographics hd_ws_bill
           ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN   customer cust_ws_ship
           ON ws.ws_ship_customer_sk = cust_ws_ship.c_customer_sk
    JOIN   customer_demographics cd_ws_ship
           ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
    JOIN   household_demographics hd_ws_ship
           ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    WHERE  rc.c_customer_sk NOT IN (
               SELECT c2.c_customer_sk
               FROM   customer c2
               WHERE  c2.c_preferred_cust_flag = 'Y'
           )
    GROUP BY rc.c_customer_sk, rc.c_first_name, rc.c_last_name, rc.c_birth_year
    HAVING SUM(cs.cs_ext_sales_price) > 10000
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.catalog_sales_amount,
    cs.web_sales_amount,
    cs.catalog_orders,
    cs.web_orders,
    cs.higher_source,
    LAG(cs.catalog_sales_amount) OVER (PARTITION BY cs.c_birth_year ORDER BY cs.catalog_sales_amount DESC) AS prev_birth_year_sales
FROM   customer_sales cs
ORDER BY cs.catalog_sales_amount DESC
LIMIT 100
