WITH catalog_customers AS (
    SELECT DISTINCT cs.cs_bill_customer_sk AS cust_id
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE p.p_channel_event = 'N'
      AND t.t_hour BETWEEN 9 AND 17
      AND cs.cs_ext_sales_price > 1000
),
store_customers AS (
    SELECT DISTINCT ss.ss_customer_sk AS cust_id
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE p.p_channel_email = 'N'
      AND t.t_hour BETWEEN 9 AND 17
      AND ss.ss_ext_sales_price > 1000
),
intersect_customers AS (
    SELECT cust_id FROM catalog_customers
    INTERSECT
    SELECT cust_id FROM store_customers
)
SELECT
    ic.cust_id,
    ROW_NUMBER() OVER (ORDER BY ic.cust_id) AS rn
FROM intersect_customers ic
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_customer_sk = ic.cust_id
      AND r.r_reason_desc LIKE '%defect%'
)
LIMIT 100
