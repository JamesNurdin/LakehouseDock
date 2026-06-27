WITH catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'catalog' AS channel,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_ext_discount_amt AS discount_amount,
        cs.cs_net_profit AS profit_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
),
store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'store' AS channel,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_ext_discount_amt AS discount_amount,
        ss.ss_net_profit AS profit_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'web' AS channel,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_ext_discount_amt AS discount_amount,
        ws.ws_net_profit AS profit_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
)
SELECT
    channel,
    d_year,
    d_month_seq,
    i_category,
    sum(sales_amount) AS total_sales_amount,
    sum(discount_amount) AS total_discount_amount,
    sum(profit_amount) AS total_profit_amount,
    sum(sales_amount - discount_amount) AS total_net_sales_amount,
    sum(discount_amount) / nullif(sum(sales_amount), 0) AS avg_discount_pct
FROM (
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
) combined
GROUP BY channel, d_year, d_month_seq, i_category
ORDER BY channel, d_year, d_month_seq, i_category
