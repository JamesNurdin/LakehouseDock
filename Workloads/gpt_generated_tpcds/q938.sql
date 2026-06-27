WITH all_sales AS (
    SELECT
        ss_item_sk AS item_sk,
        ss_promo_sk AS promo_sk,
        ss_cdemo_sk AS cdemo_sk,
        ss_quantity AS quantity,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit,
        ss_ext_discount_amt AS ext_discount_amt
    FROM store_sales
    UNION ALL
    SELECT
        cs_item_sk,
        cs_promo_sk,
        cs_bill_cdemo_sk,
        cs_quantity,
        cs_net_paid,
        cs_net_profit,
        cs_ext_discount_amt
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_item_sk,
        ws_promo_sk,
        ws_bill_cdemo_sk,
        ws_quantity,
        ws_net_paid,
        ws_net_profit,
        ws_ext_discount_amt
    FROM web_sales
)
SELECT
    p.p_promo_name,
    i.i_category,
    cd.cd_gender,
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.net_paid) AS total_net_paid,
    SUM(s.net_profit) AS total_net_profit,
    AVG(s.ext_discount_amt) AS avg_discount_amount,
    CASE
        WHEN SUM(s.net_paid) = 0 THEN 0
        ELSE SUM(s.net_profit) / SUM(s.net_paid)
    END AS profit_margin
FROM all_sales s
JOIN promotion p ON s.promo_sk = p.p_promo_sk
JOIN item i ON s.item_sk = i.i_item_sk
JOIN customer_demographics cd ON s.cdemo_sk = cd.cd_demo_sk
WHERE p.p_discount_active = 'Y'
GROUP BY p.p_promo_name, i.i_category, cd.cd_gender
ORDER BY total_net_profit DESC
LIMIT 20
