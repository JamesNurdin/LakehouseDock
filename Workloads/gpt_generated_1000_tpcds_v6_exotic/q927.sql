WITH sales_filtered AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        regexp_extract(i.i_product_name, '([0-9]{2,})') AS product_code,
        ss.ss_customer_sk,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_promo_name LIKE '%Holiday%'
      AND regexp_like(i.i_product_name, '[0-9]{2,}')
)
SELECT
    sf.d_year,
    sf.d_month_seq,
    sf.product_code,
    SUM(sf.ss_net_profit) AS total_profit,
    COUNT(DISTINCT sf.ss_customer_sk) AS distinct_customers,
    ROW_NUMBER() OVER (ORDER BY SUM(sf.ss_net_profit) DESC) AS profit_rank
FROM sales_filtered sf
GROUP BY sf.d_year, sf.d_month_seq, sf.product_code
ORDER BY total_profit DESC
LIMIT 100
