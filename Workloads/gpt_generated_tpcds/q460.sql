WITH store_sales_promo AS (
    SELECT
        d_sale.d_year AS year,
        d_sale.d_month_seq AS month_seq,
        i.i_category AS category,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d_sale
        ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE d_sale.d_date BETWEEN d_start.d_date AND d_end.d_date
      AND d_sale.d_year = 2001
),
web_sales_promo AS (
    SELECT
        d_sale.d_year AS year,
        d_sale.d_month_seq AS month_seq,
        i.i_category AS category,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d_sale
        ON ws.ws_sold_date_sk = d_sale.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE d_sale.d_date BETWEEN d_start.d_date AND d_end.d_date
      AND d_sale.d_year = 2001
),
combined AS (
    SELECT year, month_seq, category, net_profit FROM store_sales_promo
    UNION ALL
    SELECT year, month_seq, category, net_profit FROM web_sales_promo
)
SELECT
    year,
    month_seq,
    category,
    SUM(net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count
FROM combined
GROUP BY year, month_seq, category
ORDER BY year, month_seq, category
