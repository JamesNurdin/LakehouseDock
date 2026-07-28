WITH avg_price AS (
    SELECT avg(i_current_price) AS avg_price
    FROM tpcds.item
),
email_promos AS (
    SELECT DISTINCT p.p_promo_sk
    FROM tpcds.promotion p
    WHERE p.p_channel_email = 'Y'
)
SELECT state,
       total_sales,
       sales_type
FROM (
    SELECT ca.ca_state AS state,
           SUM(cs.cs_net_paid_inc_tax) AS total_sales,
           'bill' AS sales_type
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > (SELECT avg_price FROM avg_price)
    GROUP BY ca.ca_state

    UNION ALL

    SELECT ca.ca_state AS state,
           SUM(cs.cs_net_paid_inc_tax) AS total_sales,
           'ship' AS sales_type
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
    JOIN tpcds.customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN email_promos ep ON cs.cs_promo_sk = ep.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
) combined
ORDER BY total_sales DESC
LIMIT 100
