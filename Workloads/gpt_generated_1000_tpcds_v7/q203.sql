WITH billed AS (
   SELECT
       ca.ca_city AS city,
       hd.hd_buy_potential AS buy_potential,
       SUM(cs.cs_net_paid) AS total_net_paid,
       COUNT(DISTINCT cs.cs_order_number) AS orders
   FROM tpcds.catalog_sales cs
   JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE hd.hd_dep_count >= 3
     AND ca.ca_gmt_offset = -5.00
   GROUP BY ca.ca_city, hd.hd_buy_potential
),
shipped AS (
   SELECT
       ca.ca_city AS city,
       hd.hd_buy_potential AS buy_potential,
       SUM(cs.cs_net_paid) AS total_net_paid,
       COUNT(DISTINCT cs.cs_order_number) AS orders
   FROM tpcds.catalog_sales cs
   JOIN tpcds.customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
   JOIN tpcds.household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
   WHERE hd.hd_vehicle_count > 0
     AND ca.ca_location_type = 'apartment'
   GROUP BY ca.ca_city, hd.hd_buy_potential
)
SELECT city,
       buy_potential,
       total_net_paid,
       orders,
       'Billed' AS side
FROM billed
UNION ALL
SELECT city,
       buy_potential,
       total_net_paid,
       orders,
       'Shipped' AS side
FROM shipped
ORDER BY total_net_paid DESC
LIMIT 20
