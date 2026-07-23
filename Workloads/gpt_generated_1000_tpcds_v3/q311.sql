WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ext_discount_amt,
        cs.cs_net_paid,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '(?i)blue')
      AND p.p_promo_name LIKE '%Summer%'
      AND ca.ca_zip LIKE '9%'
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_item_sk = cs.cs_item_sk
            AND ws.ws_quantity > 5
      )
)
SELECT
    p.p_promo_name,
    i.i_category,
    CONCAT(p.p_promo_name, ' - ', i.i_category) AS promo_category,
    SUBSTR(p.p_promo_name, 1, 10) AS promo_name_prefix,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    (SELECT AVG(cs2.cs_ext_discount_amt) FROM catalog_sales cs2) AS overall_avg_discount
FROM filtered_sales cs
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
GROUP BY
    p.p_promo_name,
    i.i_category,
    CONCAT(p.p_promo_name, ' - ', i.i_category),
    SUBSTR(p.p_promo_name, 1, 10)
HAVING
    AVG(cs.cs_ext_discount_amt) > (SELECT AVG(cs3.cs_ext_discount_amt) FROM catalog_sales cs3) * 0.5
ORDER BY total_net_paid DESC
LIMIT 100
