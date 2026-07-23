WITH filtered_customers AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_first_name,
        c_last_name,
        c_email_address,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        SUBSTRING(c_email_address FROM POSITION('@' IN c_email_address) + 1) AS email_domain
    FROM tpcds.customer
    WHERE REGEXP_LIKE(c_email_address, '^[A-Za-z0-9._%+-]+@gmail\\.com$')
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    REGEXP_EXTRACT(p.p_promo_name, '(\\d{4})') AS promo_year,
    COUNT(DISTINCT fc.c_customer_sk) AS distinct_customers,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    (SELECT COUNT(*) FROM tpcds.store_sales) AS overall_sales_count
FROM tpcds.store_sales ss
JOIN filtered_customers fc ON ss.ss_customer_sk = fc.c_customer_sk
JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND p.p_channel_event = 'Y'
  AND p.p_promo_name LIKE '%2020%'
  AND EXISTS (
      SELECT 1
      FROM tpcds.inventory i
      WHERE i.inv_item_sk = ss.ss_item_sk
        AND i.inv_quantity_on_hand > 0
  )
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    REGEXP_EXTRACT(p.p_promo_name, '(\\d{4})')
HAVING
    SUM(ss.ss_net_profit) > 10000
    AND COUNT(DISTINCT fc.c_customer_sk) > 5
ORDER BY total_profit DESC
LIMIT 100
