WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        p.p_promo_id,
        p.p_promo_name,
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_sold.d_day_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(p.p_cost) AS avg_promo_cost,
        COUNT(DISTINCT ss.ss_ticket_number) AS ticket_count,
        MIN(d_cp_end.d_date) AS catalog_end_date,
        MIN(d_promo_start.d_date) AS promo_start_date,
        MAX(d_promo_end.d_date) AS promo_end_date,
        MAX(d_store_closed.d_date) AS store_closed_date
    FROM store_sales ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_sold.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        p.p_promo_id,
        p.p_promo_name,
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_sold.d_day_name
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    p_promo_id,
    p_promo_name,
    cp_catalog_page_id,
    cp_catalog_page_number,
    d_year,
    d_month_seq,
    d_day_name,
    total_sales,
    total_profit,
    avg_promo_cost,
    ticket_count,
    catalog_end_date,
    promo_start_date,
    promo_end_date,
    store_closed_date,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
