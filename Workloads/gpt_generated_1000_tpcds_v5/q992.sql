WITH billing_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        ca.ca_city,
        ca.ca_state,
        t.t_hour,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cs.cs_net_paid DESC) AS rn
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE ca.ca_location_type = 'condo'
      AND t.t_meal_time = 'breakfast'
      AND cd.cd_marital_status = 'M'
      AND cs.cs_net_paid > (
            SELECT avg(cs2.cs_net_paid)
            FROM catalog_sales cs2
            WHERE cs2.cs_bill_addr_sk = ca.ca_address_sk
        )
      AND EXISTS (
            SELECT 1
            FROM customer_demographics cd2
            WHERE cd2.cd_demo_sk = cs.cs_bill_cdemo_sk
              AND cd2.cd_credit_rating = 'Excellent'
        )
),
shipping_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        ca.ca_city,
        ca.ca_state,
        t.t_hour,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cs.cs_net_paid DESC) AS rn
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE ca.ca_suite_number = 'Suite 100'
      AND t.t_meal_time = 'dinner'
      AND cd.cd_dep_college_count >= 4
      AND cs.cs_net_paid > (
            SELECT avg(cs2.cs_net_paid)
            FROM catalog_sales cs2
            WHERE cs2.cs_ship_addr_sk = ca.ca_address_sk
        )
      AND EXISTS (
            SELECT 1
            FROM customer_demographics cd2
            WHERE cd2.cd_demo_sk = cs.cs_ship_cdemo_sk
              AND cd2.cd_credit_rating = 'Excellent'
        )
)
SELECT *
FROM (
    SELECT * FROM billing_sales
    UNION ALL
    SELECT * FROM shipping_sales
) AS combined
ORDER BY cs_net_paid DESC, cs_order_number
LIMIT 100
