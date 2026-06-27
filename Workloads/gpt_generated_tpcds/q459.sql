WITH sales_by_store_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        i.i_category,
        p.p_promo_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_year, d.d_month_seq, s.s_store_name, i.i_category, p.p_promo_name
)
SELECT
    d_year,
    d_month_seq,
    s_store_name,
    i_category,
    p_promo_name,
    total_net_paid,
    total_net_profit,
    total_discount / NULLIF(total_quantity, 0) AS avg_discount_per_item,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_by_store_month
WHERE total_net_profit > 50000
ORDER BY total_net_paid DESC
LIMIT 20
