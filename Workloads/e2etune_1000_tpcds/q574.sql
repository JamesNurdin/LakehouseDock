WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(COALESCE(p.p_cost, 0)) AS total_promo_cost
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_state = 'CA'
      AND d.d_year BETWEEN 2020 AND 2022
      AND i.i_category IN ('Sports', 'Clothing')
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE s.s_state = 'CA'
      AND d.d_year BETWEEN 2020 AND 2022
      AND i.i_category IN ('Sports', 'Clothing')
    GROUP BY s.s_store_sk, d.d_year, d.d_month_seq, i.i_category
)
SELECT
    sa.s_store_name,
    sa.d_year,
    sa.d_month_seq,
    sa.i_category,
    sa.total_sales,
    sa.total_quantity,
    sa.total_net_profit,
    COALESCE(ra.total_net_loss, 0) AS total_return_loss,
    (sa.total_net_profit - COALESCE(ra.total_net_loss, 0) - sa.total_promo_cost) AS adjusted_profit,
    RANK() OVER (PARTITION BY sa.s_store_name, sa.d_year ORDER BY (sa.total_net_profit - COALESCE(ra.total_net_loss, 0) - sa.total_promo_cost) DESC) AS profit_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_sk = ra.s_store_sk
   AND sa.d_year = ra.d_year
   AND sa.d_month_seq = ra.d_month_seq
   AND sa.i_category = ra.i_category
ORDER BY sa.s_store_name, sa.d_year, sa.d_month_seq, adjusted_profit DESC
