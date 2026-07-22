WITH catalog AS (
    SELECT
        p.p_promo_sk AS promo_sk,
        p.p_promo_name AS promo_name,
        i.i_item_sk AS item_sk,
        i.i_item_desc AS item_desc,
        i.i_product_name AS product_name,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE p.p_promo_name LIKE '%SAVE%'
      AND regexp_like(p.p_promo_name, '^SAVE[0-9]+')
      AND regexp_like(i.i_item_desc, '\\d{5}')
      AND d.d_year = 2001
),
web AS (
    SELECT
        p.p_promo_sk AS promo_sk,
        p.p_promo_name AS promo_name,
        i.i_item_sk AS item_sk,
        i.i_item_desc AS item_desc,
        i.i_product_name AS product_name,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE p.p_promo_name LIKE '%SAVE%'
      AND regexp_like(p.p_promo_name, '^SAVE[0-9]+')
      AND regexp_like(i.i_item_desc, '\\d{5}')
      AND d.d_year = 2001
)
SELECT
    promo_sk,
    promo_name,
    concat(promo_name, ' - ', product_name) AS promo_item,
    substr(item_desc, 1, 10) AS item_desc_prefix,
    year,
    month_seq,
    sum(net_profit) AS total_net_profit
FROM (
    SELECT promo_sk, promo_name, item_sk, item_desc, product_name, year, month_seq, net_profit FROM catalog
    UNION ALL
    SELECT promo_sk, promo_name, item_sk, item_desc, product_name, year, month_seq, net_profit FROM web
) AS combined
GROUP BY
    promo_sk,
    promo_name,
    concat(promo_name, ' - ', product_name),
    substr(item_desc, 1, 10),
    year,
    month_seq
ORDER BY total_net_profit DESC
LIMIT 100
