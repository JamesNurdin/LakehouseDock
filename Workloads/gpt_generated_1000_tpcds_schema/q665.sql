WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        CASE
            WHEN SUM(cs.cs_ext_sales_price) > SUM(ss.ss_ext_sales_price) THEN 'CATALOG'
            ELSE 'STORE'
        END AS top_channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_rec_end_date = DATE '2000-10-26'
    GROUP BY GROUPING SETS (
        (i.i_item_sk, i.i_category, i.i_brand),
        (i.i_category, i.i_brand)
    )
)
SELECT DISTINCT order_or_ticket
FROM (
    SELECT cs.cs_order_number AS order_or_ticket
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_street_type = 'Circle'
      AND cs.cs_item_sk IN (
          SELECT i_item_sk
          FROM item_sales
          WHERE top_channel = 'CATALOG'
      )
      AND EXISTS (
          SELECT 1
          FROM store_sales ss
          WHERE ss.ss_item_sk = cs.cs_item_sk
            AND ss.ss_sales_price > (
                SELECT MAX(ss2.ss_sales_price)
                FROM store_sales ss2
                WHERE ss2.ss_sales_price < 100
            )
      )
    INTERSECT
    SELECT ss.ss_ticket_number AS order_or_ticket
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_street_type = 'Parkway'
      AND ss.ss_sales_price > 30
) AS intersected
LIMIT 100
