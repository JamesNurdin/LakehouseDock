WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        d.d_year,
        st.s_store_name,
        i.i_item_desc,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '(Summer|Winter)', 1) AS promo_season,
        concat(st.s_store_name, ' - ', i.i_item_desc) AS store_item_desc
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store st ON ss.ss_store_sk = st.s_store_sk
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND regexp_like(p.p_promo_name, '(?i)Summer|Winter')
      AND i.i_item_desc LIKE '%BRIGHT%'
)
SELECT
    store_item_desc,
    promo_season,
    d_year,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(ss_ext_sales_price) AS total_sales,
    COUNT(*) AS transactions
FROM filtered_sales
GROUP BY
    store_item_desc,
    promo_season,
    d_year
HAVING SUM(ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
