WITH sales_agg AS (
    SELECT
        cc.cc_company_name,
        cc.cc_manager,
        s.s_store_name,
        s.s_city,
        p.p_promo_name,
        d_sale.d_date AS sale_date,
        d_cc_open.d_date AS cc_open_date,
        d_cc_close.d_date AS cc_close_date,
        d_store_closed.d_date AS store_closed_date,
        d_promo_start.d_date AS promo_start_date,
        d_promo_end.d_date AS promo_end_date,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS num_transactions
    FROM store_sales ss
    JOIN date_dim d_sale
        ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_close
        ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
    WHERE d_sale.d_year = 2022
    GROUP BY
        cc.cc_company_name,
        cc.cc_manager,
        s.s_store_name,
        s.s_city,
        p.p_promo_name,
        d_sale.d_date,
        d_cc_open.d_date,
        d_cc_close.d_date,
        d_store_closed.d_date,
        d_promo_start.d_date,
        d_promo_end.d_date
)
SELECT
    cc_company_name,
    cc_manager,
    s_store_name,
    s_city,
    p_promo_name,
    sale_date,
    cc_open_date,
    cc_close_date,
    store_closed_date,
    promo_start_date,
    promo_end_date,
    total_sales,
    total_profit,
    num_transactions,
    ROW_NUMBER() OVER (PARTITION BY cc_company_name ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
