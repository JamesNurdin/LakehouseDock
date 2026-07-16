WITH all_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_promo_sk AS promo_sk,
           cs.cs_call_center_sk AS channel_sk,
           cs.cs_quantity AS quantity,
           cs.cs_ext_sales_price AS sales_price,
           cs.cs_net_profit AS net_profit,
           cs.cs_coupon_amt AS coupon_amt,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_promo_sk,
           ss.ss_store_sk,
           ss.ss_quantity,
           ss.ss_ext_sales_price,
           ss.ss_net_profit,
           ss.ss_coupon_amt,
           'store'
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_promo_sk,
           ws.ws_web_page_sk,
           ws.ws_quantity,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           ws.ws_coupon_amt,
           'web'
    FROM web_sales ws
), sales_enriched AS (
    SELECT a.*,
           d.d_date,
           year(d.d_date) AS sales_year,
           month(d.d_date) AS sales_month,
           i.i_category,
           i.i_class,
           i.i_brand,
           i.i_color,
           p.p_cost AS promo_cost,
           p.p_discount_active
    FROM all_sales a
    JOIN date_dim d ON a.date_sk = d.d_date_sk
    JOIN item i ON a.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON a.promo_sk = p.p_promo_sk
), aggregated AS (
    SELECT
        sales_year,
        sales_month,
        channel,
        i_category,
        SUM(sales_price) AS total_sales,
        SUM(net_profit) AS total_profit,
        AVG(coupon_amt) AS avg_coupon,
        COUNT(DISTINCT promo_sk) AS distinct_promos,
        SUM(COALESCE(promo_cost, 0)) AS total_promo_cost,
        COUNT_IF(p_discount_active = 'Y') AS promo_active_cnt,
        COUNT(*) AS total_transactions
    FROM sales_enriched
    GROUP BY
        GROUPING SETS (
            (sales_year, sales_month, channel, i_category),
            (sales_year, sales_month, channel),
            (sales_year, channel)
        )
    HAVING SUM(net_profit) > 0
)
SELECT
    sales_year,
    sales_month,
    channel,
    i_category,
    total_sales,
    total_profit,
    avg_coupon,
    distinct_promos,
    total_promo_cost,
    promo_active_cnt,
    total_transactions,
    RANK() OVER (PARTITION BY sales_year, sales_month, channel ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY sales_year, sales_month, channel, profit_rank
LIMIT 200
