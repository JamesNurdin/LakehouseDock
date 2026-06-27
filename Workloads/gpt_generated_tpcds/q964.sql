WITH unified_sales AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_promo_sk AS promo_sk,
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid AS net_paid,
        ss.ss_ext_discount_amt AS discount_amount,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk

    UNION ALL

    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_net_paid AS net_paid,
        cs.cs_ext_discount_amt AS discount_amount,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk

    UNION ALL

    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_promo_sk AS promo_sk,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_paid AS net_paid,
        ws.ws_ext_discount_amt AS discount_amount,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
)
SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    SUM(us.net_profit) AS total_net_profit,
    SUM(us.net_paid) AS total_net_paid,
    SUM(us.discount_amount) AS total_discount_amount,
    COUNT(*) AS sales_transactions
FROM unified_sales us
JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
JOIN item i ON us.item_sk = i.i_item_sk
GROUP BY d.d_year, d.d_moy, i.i_category
ORDER BY d.d_year, d.d_moy, i.i_category
