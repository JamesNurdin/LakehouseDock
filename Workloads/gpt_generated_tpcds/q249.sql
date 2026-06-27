WITH combined_sales AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount_amt,
        ss.ss_promo_sk AS promo_sk,
        'store' AS channel
    FROM store_sales ss

    UNION ALL

    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_promo_sk AS promo_sk,
        'web' AS channel
    FROM web_sales ws
),
sales_with_dims AS (
    SELECT
        cs.channel,
        i.i_category,
        d_sold.d_year,
        d_sold.d_month_seq,
        cs.net_paid,
        cs.net_profit,
        cs.discount_amt,
        p.p_promo_sk,
        d_start.d_date AS promo_start_date,
        d_end.d_date AS promo_end_date,
        d_sold.d_date AS sale_date
    FROM combined_sales cs
    JOIN date_dim d_sold
        ON cs.sold_date_sk = d_sold.d_date_sk
    JOIN item i
        ON cs.item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON cs.promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    LEFT JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
)
SELECT
    channel,
    i_category,
    d_year,
    d_month_seq,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    SUM(discount_amt) AS total_discount,
    SUM(CASE WHEN sale_date BETWEEN promo_start_date AND promo_end_date THEN net_paid ELSE 0 END) AS promo_net_paid,
    SUM(CASE WHEN sale_date BETWEEN promo_start_date AND promo_end_date THEN net_profit ELSE 0 END) AS promo_net_profit,
    (SUM(CASE WHEN sale_date BETWEEN promo_start_date AND promo_end_date THEN net_paid ELSE 0 END) * 100.0) / NULLIF(SUM(net_paid), 0) AS promo_sales_pct
FROM sales_with_dims
GROUP BY channel, i_category, d_year, d_month_seq
ORDER BY channel, i_category, d_year, d_month_seq
