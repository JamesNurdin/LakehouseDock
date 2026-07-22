WITH eco_items AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_item_desc,
           regexp_extract(i.i_item_desc, '(?i)(eco\\w*)', 1) AS eco_keyword,
           concat(i.i_item_id, '-', regexp_extract(i.i_item_desc, '(?i)(eco\\w*)', 1)) AS item_key,
           substring(i.i_item_desc, 1, 10) AS item_desc_prefix
    FROM item i
    WHERE regexp_like(i.i_item_desc, '(?i)eco')
      AND i.i_item_desc LIKE '%eco%'
)
SELECT 
    ei.item_key,
    ei.i_item_id,
    ei.item_desc_prefix,
    ei.eco_keyword,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
    CASE WHEN pi.p_item_sk IS NOT NULL THEN TRUE ELSE FALSE END AS has_promotion
FROM eco_items ei
LEFT JOIN promotion pi
  ON pi.p_item_sk = ei.i_item_sk
JOIN web_sales ws
  ON ws.ws_item_sk = ei.i_item_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451060
  AND EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_customer_sk = ws.ws_bill_customer_sk
          AND c.c_preferred_cust_flag = 'Y'
          AND c.c_email_address LIKE '%@example.com'
          AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      )
GROUP BY ei.item_key, ei.i_item_id, ei.item_desc_prefix, ei.eco_keyword, pi.p_item_sk
ORDER BY total_net_paid DESC
LIMIT 100
