WITH high_profit_sales AS (
    SELECT
        c.c_customer_id AS customer_id,
        d.d_date AS sale_date,
        p.p_promo_name AS promo_name,
        ss.ss_net_profit AS net_profit
    FROM tpcds.store_sales ss
    INNER JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2002
      AND p.p_channel_demo = 'N'
      AND ss.ss_net_profit > 0
),
birthday_sales AS (
    SELECT
        c.c_customer_id AS customer_id,
        d.d_date AS sale_date,
        p.p_promo_name AS promo_name,
        ss.ss_net_profit AS net_profit
    FROM tpcds.store_sales ss
    INNER JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE c.c_birth_month = 12
      AND c.c_birth_day = 27
      AND ss.ss_coupon_amt > 0
)
SELECT customer_id, sale_date, promo_name, net_profit
FROM high_profit_sales
UNION ALL
SELECT customer_id, sale_date, promo_name, net_profit
FROM birthday_sales
ORDER BY net_profit DESC, sale_date ASC
LIMIT 100
