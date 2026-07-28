WITH web_profit AS (
    SELECT
        c.c_customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUM(ws.ws_net_profit) AS total_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
catalog_loss AS (
    SELECT
        c.c_customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        -SUM(cr.cr_net_loss) AS total_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT *
FROM (
    SELECT
        customer_id,
        customer_name,
        total_amount,
        'Web Sales' AS source
    FROM (
        SELECT
            c.c_customer_id AS customer_id,
            concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
            SUM(ws.ws_net_profit) AS total_amount
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        WHERE d.d_year = 2022
        GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
        ORDER BY total_amount DESC
        LIMIT 5
    )
) UNION ALL
SELECT *
FROM (
    SELECT
        customer_id,
        customer_name,
        total_amount,
        'Catalog Returns' AS source
    FROM (
        SELECT
            c.c_customer_id AS customer_id,
            concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
            -SUM(cr.cr_net_loss) AS total_amount
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        WHERE d.d_year = 2022
        GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
        ORDER BY total_amount DESC
        LIMIT 5
    )
) 
ORDER BY total_amount DESC
