WITH sales_data AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        s.s_store_name,
        d.d_year,
        cs.cs_net_paid               AS cs_net_paid,
        ss.ss_net_paid               AS ss_net_paid,
        cs.cs_ext_discount_amt       AS cs_discount,
        ss.ss_ext_discount_amt       AS ss_discount,
        sm.sm_type                   AS ship_type,
        ca.ca_country                AS bill_country,
        ca2.ca_country               AS ship_country
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer cu
      ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_address ca2
      ON cs.cs_ship_addr_sk = ca2.ca_address_sk
    JOIN store_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk
     AND ss.ss_item_sk = i.i_item_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t2
      ON ss.ss_sold_time_sk = t2.t_time_sk
    JOIN customer cu2
      ON ss.ss_customer_sk = cu2.c_customer_sk
    JOIN customer_address ca3
      ON ss.ss_addr_sk = ca3.ca_address_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
      AND i.i_brand = 'Brand#12'
      AND s.s_market_id IN (1, 3, 5)
      AND ca.ca_country = 'United States'
      AND sm.sm_type = 'AIR'
      AND cs.cs_net_paid > 1000
)
SELECT
    i_item_id,
    i_product_name,
    SUM(total_net_paid)               AS total_net_paid,
    AVG(avg_discount_per_sale)        AS avg_discount_per_sale
FROM (
    SELECT
        i_item_id,
        i_product_name,
        (cs_net_paid + ss_net_paid)                      AS total_net_paid,
        (cs_discount + ss_discount) / 2.0                AS avg_discount_per_sale
    FROM sales_data
) sub
GROUP BY i_item_id, i_product_name
HAVING SUM(total_net_paid) > 5000
ORDER BY total_net_paid DESC
LIMIT 100
