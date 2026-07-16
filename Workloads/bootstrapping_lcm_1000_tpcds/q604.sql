SELECT
    d_sale.d_year,
    d_sale.d_month_seq,
    s.s_store_id,
    s.s_state,
    s.s_city,
    p.p_promo_id,
    p.p_purpose,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_tickets,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_return_quantity,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
    SUM(ss.ss_ext_sales_price) - SUM(COALESCE(sr.sr_return_amt, 0)) AS net_sales_after_returns,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_per_sale,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(date_diff('day', d_promo_start.d_date, d_promo_end.d_date)) AS avg_promo_duration_days,
    AVG(date_diff('day', d_sale.d_date, d_closed.d_date)) AS avg_days_to_store_closure
FROM
    store_sales ss
    JOIN date_dim d_sale
        ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_returned_date_sk = d_sale.d_date_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE
    d_sale.d_year = 2020
    AND s.s_state = 'CA'
GROUP BY
    d_sale.d_year,
    d_sale.d_month_seq,
    s.s_store_id,
    s.s_state,
    s.s_city,
    p.p_promo_id,
    p.p_purpose
HAVING
    SUM(ss.ss_ext_sales_price) > 50000
ORDER BY
    net_sales_after_returns DESC
LIMIT 100
