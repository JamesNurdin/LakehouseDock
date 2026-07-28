WITH sales_customer AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_bill_customer_sk,
        c.c_customer_sk,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        c.c_current_addr_sk
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_quantity >= 2
      AND cs.cs_net_paid > 1000
      AND c.c_birth_day = 12
)
SELECT
    s.s_store_name,
    s.s_city,
    sc.c_birth_month,
    COUNT(DISTINCT sc.cs_order_number) AS order_cnt,
    SUM(sc.cs_quantity) AS total_qty,
    AVG(sc.cs_quantity) AS avg_qty,
    SUM(sc.cs_net_paid) AS total_net_paid,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    MAX(sr.sr_fee) AS max_fee,
    MIN(sr.sr_fee) AS min_fee
FROM sales_customer sc
JOIN store_returns sr
    ON sr.sr_customer_sk = sc.c_customer_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
WHERE s.s_floor_space > 7000000
  AND sr.sr_refunded_cash > 30
  AND sr.sr_fee < 50
  AND s.s_geography_class = 'Unknown'
GROUP BY s.s_store_name, s.s_city, sc.c_birth_month
HAVING SUM(sc.cs_net_paid) > 50000
   AND COUNT(*) > 10
ORDER BY total_net_paid DESC
LIMIT 100
