WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        p.p_promo_id,
        p.p_promo_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_promo_start.d_date AS promo_start_date,
        d_promo_end.d_date AS promo_end_date,
        d_web_open.d_date AS web_open_date,
        d_web_close.d_date AS web_close_date,
        w.web_name,
        w.web_country,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS transaction_count,
        AVG(ss.ss_quantity) AS avg_quantity,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) = 0 THEN NULL
            ELSE ROUND(SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price), 4)
        END AS profit_margin
    FROM store_sales ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = d_sold.d_date_sk
    JOIN date_dim d_web_open
        ON w.web_open_date_sk = d_web_open.d_date_sk
    JOIN date_dim d_web_close
        ON w.web_close_date_sk = d_web_close.d_date_sk
    WHERE d_sold.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
      AND d_sold.d_date <= d_store_closed.d_date
      AND d_sold.d_date BETWEEN d_web_open.d_date AND d_web_close.d_date
      AND p.p_discount_active = 'Y'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        p.p_promo_id,
        p.p_promo_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_promo_start.d_date,
        d_promo_end.d_date,
        d_web_open.d_date,
        d_web_close.d_date,
        w.web_name,
        w.web_country
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_sales DESC) AS sales_rank_by_store,
    PERCENT_RANK() OVER (ORDER BY total_sales DESC) AS overall_sales_percentile
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
