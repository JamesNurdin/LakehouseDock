WITH agg AS (
    SELECT
        d.d_date AS sale_date,
        d.d_year AS d_year,
        s.s_store_name AS s_store_name,
        s.s_city AS s_city,
        s.s_state AS s_state,
        s.s_country AS s_country,
        p.p_promo_name AS p_promo_name,
        p.p_channel_tv AS p_channel_tv,
        d_start.d_date AS promo_start_date,
        d_end.d_date AS promo_end_date,
        date_diff('day', d_start.d_date, d_end.d_date) AS promo_duration_days,
        d_closed.d_date AS store_closed_date,
        SUM(ss.ss_quantity) AS total_qty_sold,
        SUM(ss.ss_sales_price * ss.ss_quantity) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
        SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_return_amt, 0)) AS net_profit_after_returns
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d.d_year = 2022
      AND d.d_date BETWEEN d_start.d_date AND d_end.d_date
    GROUP BY
        d.d_date,
        d.d_year,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country,
        p.p_promo_name,
        p.p_channel_tv,
        d_start.d_date,
        d_end.d_date,
        d_closed.d_date
)
SELECT
    sale_date,
    d_year,
    s_store_name,
    s_city,
    s_state,
    s_country,
    p_promo_name,
    p_channel_tv,
    promo_start_date,
    promo_end_date,
    promo_duration_days,
    store_closed_date,
    total_qty_sold,
    total_sales_amount,
    total_net_profit,
    total_return_amount,
    net_profit_after_returns,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY net_profit_after_returns DESC) AS profit_rank
FROM agg
ORDER BY net_profit_after_returns DESC
LIMIT 100
