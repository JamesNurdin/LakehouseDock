WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        d.d_year,
        d.d_month_seq,
        i.i_category_id,
        i.i_category,
        p.p_promo_name,
        p.p_channel_tv,
        cc.cc_name,
        wp.wp_type
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category_id = 3
      AND p.p_channel_tv = 'N'
      AND ss.ss_quantity > 5
)
SELECT
    d_year,
    i_category,
    p_promo_name,
    cc_name,
    wp_type,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_ext_discount_amt) AS avg_discount,
    SUM(ss_net_profit) AS total_profit,
    COUNT(*) AS transaction_count
FROM base
GROUP BY
    d_year,
    i_category,
    p_promo_name,
    cc_name,
    wp_type
ORDER BY total_sales DESC
LIMIT 100
