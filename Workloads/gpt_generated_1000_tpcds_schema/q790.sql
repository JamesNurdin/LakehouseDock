WITH promo_valid AS (
    SELECT p.p_promo_sk,
           p.p_promo_id,
           p.p_channel_email,
           p.p_discount_active,
           p.p_promo_name
    FROM promotion p
    WHERE p.p_channel_email = 'Y'
      AND p.p_discount_active = 'Y'
      AND p.p_start_date_sk >= 2450000
      AND p.p_end_date_sk <= 2459999
),
sales_agg AS (
    SELECT ws.ws_promo_sk,
           ws.ws_bill_customer_sk,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           AVG(ws.ws_ext_tax) AS avg_tax,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(*) AS sales_cnt
    FROM web_sales ws
    WHERE ws.ws_ext_tax > 10
      AND ws.ws_net_paid > 500
      AND ws.ws_quantity >= 1
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY ws.ws_promo_sk, ws.ws_bill_customer_sk
),
promo_excluded AS (
    SELECT p.p_promo_sk
    FROM promotion p
    WHERE p.p_channel_email = 'N'
      AND p.p_discount_active = 'N'
),
promo_keys AS (
    SELECT p.p_promo_sk
    FROM promo_valid p
    EXCEPT
    SELECT e.p_promo_sk
    FROM promo_excluded e
),
cross_dim AS (
    SELECT 1 AS grp UNION ALL SELECT 2 UNION ALL SELECT 3
)
SELECT
    p.p_promo_id,
    c.c_customer_id,
    s.total_sales,
    s.avg_tax,
    s.sales_cnt,
    CASE WHEN s.total_profit > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    ld.total_discount,
    (SELECT MAX(ws2.ws_ext_tax)
       FROM web_sales ws2
       WHERE ws2.ws_promo_sk = p.p_promo_sk) AS max_tax_for_promo,
    cd.grp
FROM promo_keys pk
JOIN promo_valid p ON p.p_promo_sk = pk.p_promo_sk
JOIN sales_agg s ON s.ws_promo_sk = p.p_promo_sk
JOIN customer c ON c.c_customer_sk = s.ws_bill_customer_sk
CROSS JOIN cross_dim cd
LEFT JOIN LATERAL (
    SELECT SUM(ws3.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws3
    WHERE ws3.ws_bill_customer_sk = c.c_customer_sk
      AND ws3.ws_promo_sk = p.p_promo_sk
) ld ON TRUE
WHERE c.c_birth_day = 20
  AND c.c_birth_month = 7
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_last_review_date > 2452000
  AND p.p_promo_name IS NOT NULL
  AND s.total_sales > 1000
ORDER BY s.total_sales DESC, p.p_promo_id
LIMIT 100
