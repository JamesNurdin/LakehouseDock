SELECT
    t.s_store_id,
    t.s_store_name,
    t.d_year,
    t.d_month_seq,
    t.total_net_paid,
    t.total_net_profit,
    t.distinct_orders,
    t.avg_quantity,
    t.distinct_category_count,
    t.total_discount_amount,
    RANK() OVER (PARTITION BY t.d_year ORDER BY t.total_net_profit DESC) AS profit_rank_year
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders,
        AVG(ss.ss_quantity) AS avg_quantity,
        COUNT(DISTINCT i.i_category) AS distinct_category_count,
        SUM(CASE WHEN p.p_promo_sk IS NOT NULL THEN ss.ss_ext_discount_amt ELSE 0 END) AS total_discount_amount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year IN (2000, 2001)
      AND s.s_state = 'TX'
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq
    HAVING SUM(ss.ss_net_profit) > 0
) t
ORDER BY profit_rank_year, t.total_net_profit DESC
LIMIT 10
