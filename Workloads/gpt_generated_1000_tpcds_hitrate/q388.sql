WITH cs_sales AS (
    SELECT
        i.i_brand AS brand,
        CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END AS size_bucket,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN item i TABLESAMPLE BERNOULLI (10) ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE p.p_channel_email = 'Y'
      AND i.i_manufact LIKE 'bar%'
      AND i.i_item_sk IN (
          SELECT p2.p_item_sk
          FROM promotion p2
          WHERE p2.p_discount_active = 'Y'
      )
    GROUP BY i.i_brand,
        CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END
),
ss_sales AS (
    SELECT
        i.i_brand AS brand,
        CASE WHEN ss.ss_quantity > 5 THEN 'Large' ELSE 'Small' END AS size_bucket,
        SUM(ss.ss_ext_sales_price - COALESCE(sr.sr_return_amt, 0)) AS total_sales
    FROM store_sales ss
    JOIN item i TABLESAMPLE BERNOULLI (10) ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_zip = '10069'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = ss.ss_promo_sk
            AND p.p_discount_active = 'Y'
      )
    GROUP BY i.i_brand,
        CASE WHEN ss.ss_quantity > 5 THEN 'Large' ELSE 'Small' END
)
SELECT brand,
       size_bucket,
       total_sales
FROM cs_sales
UNION ALL
SELECT brand,
       size_bucket,
       total_sales
FROM ss_sales
ORDER BY brand,
         total_sales DESC
LIMIT 100
