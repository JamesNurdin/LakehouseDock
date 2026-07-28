WITH filtered_items AS (
    SELECT i_item_sk,
           i_item_desc,
           i_category,
           i_current_price
    FROM   item
    WHERE  regexp_like(i_item_desc, '(?i)blue|red')
)
SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       COUNT(DISTINCT cs.cs_order_number)                         AS orders,
       SUM(cs.cs_net_paid)                                         AS total_net_paid,
       SUM(cs.cs_net_paid) / NULLIF(COUNT(DISTINCT cs.cs_order_number), 0) AS avg_order_value,
       ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_net_paid) DESC)       AS sales_rank
FROM   catalog_sales cs
JOIN   filtered_items fi   ON cs.cs_item_sk = fi.i_item_sk
JOIN   customer c          ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN   date_dim d          ON cs.cs_sold_date_sk = d.d_date_sk
WHERE  d.d_year = 2001
  AND  regexp_like(c.c_email_address, '.*@[^@]+\\.com$')
  AND  cs.cs_net_paid > 0
  AND  cs.cs_quantity > 0
  AND  EXISTS (
        SELECT 1
        FROM   promotion p
        WHERE  p.p_promo_sk = cs.cs_promo_sk
          AND  p.p_discount_active = 'Y'
          AND  p.p_promo_name LIKE '%Summer%'
    )
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_net_paid DESC
LIMIT 100
