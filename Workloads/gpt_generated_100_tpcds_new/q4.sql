WITH sold_date AS (
    SELECT d_date_sk, d_date, d_year, d_weekend
    FROM date_dim
    WHERE d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
),
ship_date AS (
    SELECT d_date_sk, d_date AS ship_date
    FROM date_dim
),
inv AS (
    SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand, inv_date_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 300
),
agg AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        sd.d_year,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_quantity) AS avg_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        MIN(sd.d_date) AS first_sold_date,
        MAX(shipd.ship_date) AS last_ship_date
    FROM web_sales ws
    JOIN sold_date sd ON ws.ws_sold_date_sk = sd.d_date_sk
    JOIN ship_date shipd ON ws.ws_ship_date_sk = shipd.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN inv i ON i.inv_date_sk = sd.d_date_sk
    WHERE ws.ws_net_paid > 500
      AND c.c_birth_year BETWEEN 1950 AND 1960
      AND cd.cd_gender = 'M'
      AND sd.d_weekend = 'N'
    GROUP BY c.c_customer_id, cd.cd_gender, sd.d_year
)
SELECT
    a.c_customer_id,
    a.cd_gender,
    a.d_year,
    a.total_net_paid,
    a.avg_quantity,
    a.distinct_orders,
    a.first_sold_date,
    a.last_ship_date,
    ROW_NUMBER() OVER (PARTITION BY a.c_customer_id ORDER BY a.total_net_paid DESC) AS revenue_rank
FROM agg a
ORDER BY a.total_net_paid DESC
LIMIT 100
