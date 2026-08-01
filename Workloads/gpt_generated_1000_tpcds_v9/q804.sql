WITH bill_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_tax,
        cs.cs_ship_date_sk,
        cs.cs_list_price,
        cs.cs_ship_customer_sk,
        cs.cs_bill_customer_sk,
        c.c_customer_sk,
        c.c_customer_id,
        c.c_salutation,
        c.c_birth_year
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE c.c_salutation = 'Dr.'
      AND c.c_birth_year = 1973
      AND cs.cs_ext_tax > 100
      AND cs.cs_list_price BETWEEN 100 AND 300
      AND cs.cs_ship_date_sk = 2450900
      AND cs.cs_ship_customer_sk IN (
          SELECT c2.c_customer_sk
          FROM customer c2
          WHERE c2.c_birth_year < 1980
      )
)
SELECT
    bs.c_customer_id,
    bs.cs_order_number,
    bs.cs_net_paid,
    bs.cs_ext_tax,
    bs.cs_ship_date_sk,
    (
        SELECT MAX(wp.wp_max_ad_count)
        FROM web_page wp
        WHERE wp.wp_customer_sk = bs.c_customer_sk
    ) AS max_ad_count_for_customer,
    (
        SELECT SUM(cs3.cs_net_paid)
        FROM catalog_sales cs3
        WHERE cs3.cs_bill_customer_sk = bs.c_customer_sk
    ) AS total_net_paid_by_customer,
    RANK() OVER (ORDER BY bs.cs_net_paid DESC) AS net_paid_rank,
    ROW_NUMBER() OVER (PARTITION BY bs.c_salutation ORDER BY bs.cs_ext_tax DESC) AS rn_by_salutation
FROM bill_sales bs
WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    WHERE wp.wp_customer_sk = bs.c_customer_sk
      AND wp.wp_type = 'Home'
)
ORDER BY net_paid_rank
LIMIT 100
