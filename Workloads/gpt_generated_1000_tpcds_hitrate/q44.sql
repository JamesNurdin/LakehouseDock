(
    SELECT DISTINCT c.c_customer_id
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
      AND i.i_category = 'Sports'
      AND ss.ss_net_paid > 500
)
INTERSECT
(
    SELECT DISTINCT c.c_customer_id
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
      AND i.i_category = 'Sports'
      AND cs.cs_net_paid > 500
)
LIMIT 100
