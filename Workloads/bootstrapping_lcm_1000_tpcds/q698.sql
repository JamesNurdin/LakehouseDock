WITH return_promo_stats AS (
    SELECT
        d_ret.d_year,
        d_ret.d_quarter_name,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        p.p_promo_name,
        p.p_discount_active,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_closed.d_date AS store_closed_date,
        d_start.d_date AS promo_start_date,
        d_end.d_date AS promo_end_date,
        date_diff('day', d_start.d_date, d_end.d_date) AS promo_duration_days,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(p.p_cost) AS avg_promo_cost
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_ret.d_year BETWEEN 2020 AND 2022
      AND d_ret.d_date BETWEEN d_start.d_date AND d_end.d_date
    GROUP BY
        d_ret.d_year,
        d_ret.d_quarter_name,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        p.p_promo_name,
        p.p_discount_active,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_closed.d_date,
        d_start.d_date,
        d_end.d_date
)
SELECT
    r.d_year,
    r.d_quarter_name,
    r.i_item_id,
    r.i_product_name,
    r.i_brand,
    r.i_category,
    r.p_promo_name,
    r.p_discount_active,
    r.s_store_name,
    r.s_city,
    r.s_state,
    r.store_closed_date,
    r.promo_start_date,
    r.promo_end_date,
    r.promo_duration_days,
    r.distinct_tickets,
    r.total_return_qty,
    r.total_return_amt,
    r.total_net_loss,
    r.avg_promo_cost,
    ROW_NUMBER() OVER (ORDER BY r.total_return_amt DESC) AS overall_return_rank
FROM return_promo_stats r
ORDER BY r.total_return_amt DESC
LIMIT 100
