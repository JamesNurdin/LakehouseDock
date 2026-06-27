WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        i.i_category,
        d_sale.d_year,
        d_sale.d_month_seq,
        cs.cs_ext_sales_price AS sales_price,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_sale
        ON cs.cs_sold_date_sk = d_sale.d_date_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_sale.d_date BETWEEN d_start.d_date AND d_end.d_date

    UNION ALL

    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        i.i_category,
        d_sale.d_year,
        d_sale.d_month_seq,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d_sale
        ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_sale.d_date BETWEEN d_start.d_date AND d_end.d_date

    UNION ALL

    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        i.i_category,
        d_sale.d_year,
        d_sale.d_month_seq,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_sale
        ON ws.ws_sold_date_sk = d_sale.d_date_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_sale.d_date BETWEEN d_start.d_date AND d_end.d_date
)
SELECT
    p_promo_sk,
    p_promo_name,
    i_category,
    d_year,
    d_month_seq,
    SUM(sales_price) AS total_sales,
    SUM(discount_amt) AS total_discount,
    SUM(net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count
FROM promo_sales
GROUP BY
    p_promo_sk,
    p_promo_name,
    i_category,
    d_year,
    d_month_seq
ORDER BY total_net_profit DESC
LIMIT 100
