SELECT
    item.i_category,
    date_dim.d_year,
    date_dim.d_moy,
    sum(store_sales.ss_ext_sales_price) AS total_sales,
    sum(store_sales.ss_net_profit) AS total_profit,
    avg(store_sales.ss_ext_discount_amt) AS avg_discount_amount,
    count(DISTINCT promotion.p_promo_sk) AS distinct_promotions,
    sum(CASE WHEN customer_demographics.cd_gender = 'F' THEN store_sales.ss_ext_sales_price ELSE 0 END) / sum(store_sales.ss_ext_sales_price) AS female_sales_pct,
    sum(CASE WHEN customer_demographics.cd_gender = 'M' THEN store_sales.ss_ext_sales_price ELSE 0 END) / sum(store_sales.ss_ext_sales_price) AS male_sales_pct
FROM store_sales
JOIN date_dim
    ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
JOIN item
    ON store_sales.ss_item_sk = item.i_item_sk
LEFT JOIN promotion
    ON store_sales.ss_promo_sk = promotion.p_promo_sk
JOIN customer_demographics
    ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
WHERE date_dim.d_year = 2001
GROUP BY item.i_category, date_dim.d_year, date_dim.d_moy
ORDER BY item.i_category, date_dim.d_moy
