WITH sale_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid_inc_tax,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_promo_sk,
        i.i_item_id,
        s.s_division_name,
        s.s_hours,
        d_sale.d_dow,
        d_sale.d_day_name,
        d_start.d_date AS promo_start_date,
        d_end.d_date AS promo_end_date,
        d_misc.d_date AS promo_misc_date,
        d_closed.d_date AS store_closed_date,
        i2.i_item_id AS promo_item_id
    FROM store_sales ss
    JOIN date_dim d_sale ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    JOIN date_dim d_misc ON p.p_start_date_sk = d_misc.d_date_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN item i2 ON p.p_item_sk = i2.i_item_sk
)
SELECT
    s_division_name,
    d_day_name,
    CASE WHEN d_dow IN (0, 6) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
    SUM(ss_net_paid_inc_tax) AS total_sales,
    COUNT(DISTINCT i_item_id) AS distinct_items,
    COUNT(DISTINCT hour_part) AS distinct_hours,
    COUNT(DISTINCT promo_start_date) AS distinct_promo_start_dates
FROM sale_data
CROSS JOIN UNNEST(split(s_hours, ',')) AS t(hour_part)
GROUP BY
    s_division_name,
    d_day_name,
    CASE WHEN d_dow IN (0, 6) THEN 'Weekend' ELSE 'Weekday' END
ORDER BY total_sales DESC
LIMIT 100
