WITH catalog_agg AS (
    SELECT
        c.c_customer_sk                AS customer_sk,
        c.c_customer_id                AS customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        c.c_email_address              AS email,
        regexp_extract(c.c_email_address, '^([^@]+)@', 1) AS email_user,
        w.w_warehouse_name             AS warehouse_name,
        w.w_city                       AS warehouse_city,
        SUM(cs.cs_net_paid)            AS total_net_paid,
        'catalog'                      AS source
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city LIKE 'San%'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        w.w_warehouse_name,
        w.w_city
),

web_agg AS (
    SELECT
        c.c_customer_sk                AS customer_sk,
        c.c_customer_id                AS customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        c.c_email_address              AS email,
        regexp_extract(c.c_email_address, '^([^@]+)@', 1) AS email_user,
        w.w_warehouse_name             AS warehouse_name,
        w.w_city                       AS warehouse_city,
        SUM(ws.ws_net_paid)            AS total_net_paid,
        'web'                          AS source
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city LIKE 'San%'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        w.w_warehouse_name,
        w.w_city
),

all_sales AS (
    SELECT
        customer_sk,
        customer_id,
        customer_name,
        email,
        email_user,
        warehouse_name,
        warehouse_city,
        total_net_paid,
        source
    FROM catalog_agg
    UNION ALL
    SELECT
        customer_sk,
        customer_id,
        customer_name,
        email,
        email_user,
        warehouse_name,
        warehouse_city,
        total_net_paid,
        source
    FROM web_agg
)
SELECT
    customer_id,
    customer_name,
    email,
    email_user,
    warehouse_name,
    warehouse_city,
    total_net_paid,
    source,
    row_number() OVER (PARTITION BY source ORDER BY total_net_paid DESC) AS rank_in_source,
    (SELECT AVG(total_net_paid) FROM all_sales) AS avg_total_net_paid
FROM all_sales
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_customer_sk = all_sales.customer_sk
      AND regexp_like(r.r_reason_desc, '(?i)gift')
)
ORDER BY source, rank_in_source
LIMIT 100
