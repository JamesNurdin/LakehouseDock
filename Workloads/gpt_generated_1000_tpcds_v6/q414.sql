WITH sales_cte AS (
    SELECT
        ss.ss_sold_date_sk,
        d.d_date,
        ss.ss_store_sk,
        s.s_store_name,
        ss.ss_customer_sk,
        c.c_first_name,
        ss.ss_promo_sk,
        p.p_promo_name,
        ss.ss_quantity,
        ss.ss_net_profit,
        substring(s.s_store_name FROM 1 FOR 5) AS store_prefix,
        regexp_extract(p.p_promo_name, '(\\d{2})', 1) AS promo_digits
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE regexp_like(p.p_promo_name, '^[A-Z]{3}[0-9]{2}$')
      AND s.s_store_name LIKE '%Store%'
)
SELECT
    sc.store_prefix,
    sc.promo_digits,
    COUNT(*) AS sales_cnt,
    SUM(sc.ss_net_profit) AS total_profit,
    AVG(sc.ss_quantity) AS avg_quantity
FROM sales_cte sc
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs
    WHERE cs.cs_bill_customer_sk = sc.ss_customer_sk
      AND cs.cs_ext_sales_price > 1000
)
GROUP BY sc.store_prefix, sc.promo_digits
ORDER BY total_profit DESC
LIMIT 100
