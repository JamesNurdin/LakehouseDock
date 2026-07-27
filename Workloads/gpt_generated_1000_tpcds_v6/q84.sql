WITH bill_agg AS (
    SELECT
        cd.cd_education_status AS education_status,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 8000
      AND c.c_salutation = 'Dr.'
      AND ws.ws_ext_wholesale_cost > 1000
      AND ws.ws_list_price < 200
    GROUP BY cd.cd_education_status
),
ship_agg AS (
    SELECT
        cd.cd_education_status AS education_status,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 8000
      AND c.c_salutation = 'Mrs.'
      AND ws.ws_ext_wholesale_cost > 1500
      AND ws.ws_quantity >= 2
    GROUP BY cd.cd_education_status
)
SELECT
    education_status,
    SUM(total_net_paid) AS agg_net_paid,
    SUM(total_orders) AS agg_orders
FROM (
    SELECT * FROM bill_agg
    UNION ALL
    SELECT * FROM ship_agg
) combined
GROUP BY education_status
HAVING SUM(total_net_paid) > 20000
ORDER BY agg_net_paid DESC
LIMIT 100
