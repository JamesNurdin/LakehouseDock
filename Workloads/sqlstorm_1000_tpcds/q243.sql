WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        SUM(ss.ss_net_paid) AS sum_net_paid,
        SUM(ss.ss_net_profit) AS sum_net_profit,
        SUM(ss.ss_ext_discount_amt) AS sum_discount,
        SUM(ss.ss_quantity) AS sum_quantity,
        SUM(COALESCE(p.p_cost, 0)) AS sum_promo_cost
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY ss.ss_store_sk, d.d_year, d.d_quarter_seq, i.i_category
),
returns_agg AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        SUM(sr.sr_return_amt) AS sum_return_amt,
        SUM(sr.sr_net_loss) AS sum_return_net_loss,
        SUM(sr.sr_return_quantity) AS sum_return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY sr.sr_store_sk, d.d_year, d.d_quarter_seq, i.i_category
),
cat_ranked AS (
    SELECT
        s.store_sk,
        st.s_store_name AS store_name,
        s.d_year,
        s.d_quarter_seq,
        s.i_category,
        s.sum_net_paid,
        s.sum_net_profit,
        s.sum_discount,
        s.sum_quantity,
        s.sum_promo_cost,
        COALESCE(r.sum_return_amt, 0) AS sum_return_amt,
        COALESCE(r.sum_return_net_loss, 0) AS sum_return_net_loss,
        COALESCE(r.sum_return_quantity, 0) AS sum_return_quantity,
        (s.sum_net_paid - COALESCE(r.sum_return_amt, 0)) AS net_sales,
        (s.sum_net_profit - COALESCE(r.sum_return_net_loss, 0)) AS net_profit_adj,
        ROW_NUMBER() OVER (
            PARTITION BY s.store_sk, s.d_year, s.d_quarter_seq
            ORDER BY (s.sum_net_profit - COALESCE(r.sum_return_net_loss, 0)) DESC
        ) AS category_rank
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.store_sk = r.store_sk
        AND s.d_year = r.d_year
        AND s.d_quarter_seq = r.d_quarter_seq
        AND s.i_category = r.i_category
    JOIN store st ON s.store_sk = st.s_store_sk
)
SELECT
    cr.store_sk,
    cr.store_name,
    cr.d_year,
    cr.d_quarter_seq,
    cr.i_category,
    cr.sum_net_paid,
    cr.sum_net_profit,
    cr.sum_discount,
    cr.sum_quantity,
    cr.sum_promo_cost,
    cr.sum_return_amt,
    cr.sum_return_net_loss,
    cr.sum_return_quantity,
    cr.net_sales,
    cr.net_profit_adj,
    cr.category_rank,
    AVG(cr.net_profit_adj) OVER (
        PARTITION BY cr.store_sk
        ORDER BY cr.d_year, cr.d_quarter_seq
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS profit_3q_moving_avg
FROM cat_ranked cr
WHERE cr.category_rank <= 3
ORDER BY cr.store_sk, cr.d_year, cr.d_quarter_seq, cr.category_rank
