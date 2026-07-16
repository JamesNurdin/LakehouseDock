WITH wp_creation AS (
    SELECT wp_creation_date_sk AS d_date_sk,
           COUNT(DISTINCT wp_web_page_id) AS pages_created
    FROM web_page
    GROUP BY wp_creation_date_sk
),
wp_access AS (
    SELECT wp_access_date_sk AS d_date_sk,
           COUNT(DISTINCT wp_web_page_id) AS pages_accessed
    FROM web_page
    GROUP BY wp_access_date_sk
),
sales_agg AS (
    SELECT
        d_sale.d_year,
        d_sale.d_quarter_name,
        s.s_store_sk,
        s.s_store_name,
        p.p_promo_name,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
        COALESCE(wc.pages_created, 0) AS pages_created_on_sale_day,
        COALESCE(wa.pages_accessed, 0) AS pages_accessed_on_sale_day,
        MIN(d_store_closed.d_date) AS store_closed_date,
        MIN(d_promo_start.d_date) AS promo_start_date,
        MIN(d_promo_end.d_date) AS promo_end_date
    FROM store_sales ss
    JOIN date_dim d_sale
        ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    LEFT JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    LEFT JOIN wp_creation wc
        ON d_sale.d_date_sk = wc.d_date_sk
    LEFT JOIN wp_access wa
        ON d_sale.d_date_sk = wa.d_date_sk
    WHERE (s.s_closed_date_sk IS NULL OR s.s_closed_date_sk > d_sale.d_date_sk)
      AND p.p_start_date_sk <= d_sale.d_date_sk
      AND p.p_end_date_sk >= d_sale.d_date_sk
    GROUP BY d_sale.d_year,
             d_sale.d_quarter_name,
             s.s_store_sk,
             s.s_store_name,
             p.p_promo_name,
             wc.pages_created,
             wa.pages_accessed
    HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
    d_year,
    d_quarter_name,
    s_store_name,
    p_promo_name,
    total_net_profit,
    total_sales,
    avg_discount_amount,
    pages_created_on_sale_day,
    pages_accessed_on_sale_day,
    store_closed_date,
    promo_start_date,
    promo_end_date,
    ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY total_net_profit DESC) AS profit_rank_per_store
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
