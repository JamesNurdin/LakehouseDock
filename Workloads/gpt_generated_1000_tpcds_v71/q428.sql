WITH sales_agg AS (
    SELECT
        i.i_brand AS brand,
        p.p_promo_name AS promo_name,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(inv.inv_quantity_on_hand) AS inventory_on_hand
    FROM item i
    LEFT JOIN store_sales ss
        ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON i.i_item_sk = sr.sr_item_sk
        AND ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN web_sales ws
        ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN customer_demographics cd_ss
        ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    LEFT JOIN customer_demographics cd_sr
        ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    LEFT JOIN customer_demographics cd_ws
        ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
    WHERE
        i.i_current_price BETWEEN 1.00 AND 7.00
        AND i.i_brand_id IN (1, 2, 3)
        AND inv.inv_quantity_on_hand > 200
        AND p.p_discount_active = 'Y'
        AND ss.ss_sold_date_sk BETWEEN 2450800 AND 2451200
        AND cd_ss.cd_gender = 'M'
        AND ws.ws_quantity > 1
    GROUP BY
        GROUPING SETS (
            (i.i_brand, p.p_promo_name),
            (i.i_brand),
            (p.p_promo_name),
            ()
        )
)
SELECT
    s.brand,
    s.promo_name,
    s.store_sales_amount,
    s.store_net_profit,
    s.web_sales_amount,
    s.web_net_profit,
    s.inventory_on_hand,
    (s.store_net_profit - a.avg_store_profit) AS net_profit_vs_avg
FROM sales_agg s
CROSS JOIN (
    SELECT AVG(store_net_profit) AS avg_store_profit FROM sales_agg
) a
WHERE
    (s.store_sales_amount > 1000 OR s.web_sales_amount > 1000)
    AND s.store_net_profit > a.avg_store_profit
ORDER BY
    s.brand,
    s.promo_name,
    s.store_sales_amount DESC
LIMIT 100
