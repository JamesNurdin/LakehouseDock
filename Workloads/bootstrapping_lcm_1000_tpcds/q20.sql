WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        p.p_promo_id,
        p.p_promo_name,
        d_sold.d_year,
        d_sold.d_quarter_name,
        d_start.d_date AS promo_start_date,
        d_end.d_date AS promo_end_date,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        d_closed.d_date AS store_closed_date,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    LEFT JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_sold.d_year BETWEEN 2015 AND 2020
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_city,
        s.s_state,
        p.p_promo_id,
        p.p_promo_name,
        d_sold.d_year,
        d_sold.d_quarter_name,
        d_start.d_date,
        d_end.d_date,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        d_closed.d_date
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    s_store_id,
    s_city,
    s_state,
    p_promo_id,
    p_promo_name,
    d_year,
    d_quarter_name,
    promo_start_date,
    promo_end_date,
    hd_buy_potential,
    hd_income_band_sk,
    store_closed_date,
    distinct_customers,
    total_sales,
    total_net_profit,
    avg_discount,
    total_quantity,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank_year
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
