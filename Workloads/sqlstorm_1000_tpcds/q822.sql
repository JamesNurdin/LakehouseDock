SELECT
    d.d_year,
    d.d_month_seq,
    f.channel,
    i.i_class,
    p.p_promo_name,
    SUM(f.net_profit) AS total_net_profit,
    SUM(f.sales_amount) AS total_sales,
    AVG(f.discount_amt) AS avg_discount,
    COUNT(*) AS order_count
FROM (
    SELECT cs.cs_sold_date_sk AS date_sk,
           'catalog' AS channel,
           cs.cs_net_profit AS net_profit,
           cs.cs_ext_sales_price AS sales_amount,
           cs.cs_ext_discount_amt AS discount_amt,
           cs.cs_item_sk AS item_sk,
           cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           'store' AS channel,
           ss.ss_net_profit,
           ss.ss_ext_sales_price,
           ss.ss_ext_discount_amt,
           ss.ss_item_sk,
           ss.ss_promo_sk
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           'web' AS channel,
           ws.ws_net_profit,
           ws.ws_ext_sales_price,
           ws.ws_ext_discount_amt,
           ws.ws_item_sk,
           ws.ws_promo_sk
    FROM web_sales ws
) f
JOIN date_dim d ON f.date_sk = d.d_date_sk
JOIN item i ON f.item_sk = i.i_item_sk
LEFT JOIN promotion p ON f.promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY
    d.d_year,
    d.d_month_seq,
    f.channel,
    i.i_class,
    p.p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
