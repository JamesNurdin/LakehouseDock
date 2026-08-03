WITH sales_agg AS (
    SELECT
        c.c_customer_id AS customer_id,
        p.p_promo_name      AS promo_name,
        d.d_year            AS sales_year,
        SUM(ss.ss_net_profit)   AS total_profit,
        SUM(ss.ss_quantity)     AS total_qty
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001                                   -- filter 1
      AND c.c_birth_year BETWEEN 1960 AND 1970               -- filter 2
      AND p.p_discount_active = 'Y'                         -- filter 3
      AND w.w_state = 'CA'                                   -- filter 4
      AND i.inv_quantity_on_hand > 0                        -- filter 5
    GROUP BY c.c_customer_id, p.p_promo_name, d.d_year
)
SELECT
    promo_name,
    COUNT(DISTINCT customer_id) AS num_customers,
    AVG(total_profit)          AS avg_profit_per_customer,
    SUM(total_qty)             AS total_quantity_sold
FROM sales_agg
GROUP BY promo_name
HAVING AVG(total_profit) > 1000
ORDER BY avg_profit_per_customer DESC
LIMIT 100
