WITH cs_cust AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        c.c_customer_id,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name
    FROM catalog_sales cs
    FULL OUTER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
)
SELECT
    p.p_promo_name,
    COUNT(DISTINCT cs_cust.cs_order_number) AS distinct_orders,
    SUM(cs_cust.cs_ext_sales_price) AS total_sales,
    SUM(cs_cust.cs_ext_discount_amt) AS total_discount,
    SUBSTR(i.i_product_name, 1, 5) AS product_name_prefix,
    REGEXP_EXTRACT(cs_cust.c_email_address, '^([^@]+)@') AS email_user
FROM cs_cust
JOIN promotion p
    ON cs_cust.cs_promo_sk = p.p_promo_sk
JOIN item i
    ON cs_cust.cs_item_sk = i.i_item_sk
WHERE REGEXP_LIKE(cs_cust.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
  AND p.p_promo_name LIKE '%Discount%'
GROUP BY
    p.p_promo_name,
    i.i_product_name,
    cs_cust.c_email_address
LIMIT 100
