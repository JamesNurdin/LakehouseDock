WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_state,
        i.i_category,
        p.p_promo_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, s.s_state, i.i_category, p.p_promo_id
), returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_state,
        i.i_category,
        p.p_promo_id,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_orders
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, s.s_state, i.i_category, p.p_promo_id
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.s_state,
    s.i_category,
    s.p_promo_id AS promo_id,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    (s.total_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_adj,
    (s.total_sales - COALESCE(r.total_return_amount, 0)) AS net_sales_adj,
    RANK() OVER (PARTITION BY s.s_state ORDER BY (s.total_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank_state
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.s_state = r.s_state
   AND s.i_category = r.i_category
   AND s.p_promo_id IS NOT DISTINCT FROM r.p_promo_id
ORDER BY s.d_year, s.d_month_seq, s.s_state, s.i_category, s.p_promo_id
