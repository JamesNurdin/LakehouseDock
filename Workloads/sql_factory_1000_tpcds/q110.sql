WITH item_sales AS (
    SELECT
        cd_bill.cd_gender AS bill_gender,
        cd_ship.cd_gender AS ship_gender,
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT p.p_promo_id) AS promo_count,
        MAX(p.p_promo_name) AS example_promo_name,
        COUNT(DISTINCT w.web_site_id) AS site_count
    FROM web_sales ws
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY cd_bill.cd_gender, cd_ship.cd_gender, ws.ws_item_sk
)
SELECT
    bill_gender,
    ship_gender,
    ws_item_sk,
    total_net_profit,
    total_quantity,
    avg_sales_price,
    promo_count,
    example_promo_name,
    site_count,
    CASE
        WHEN total_net_profit > 10000 THEN 'High Profit'
        WHEN total_net_profit BETWEEN 0 AND 10000 THEN 'Moderate Profit'
        ELSE 'Low or Negative Profit'
    END AS profit_category,
    rn
FROM (
    SELECT
        bill_gender,
        ship_gender,
        ws_item_sk,
        total_net_profit,
        total_quantity,
        avg_sales_price,
        promo_count,
        example_promo_name,
        site_count,
        ROW_NUMBER() OVER (PARTITION BY bill_gender, ship_gender ORDER BY total_net_profit DESC) AS rn
    FROM item_sales
) t
WHERE rn <= 5
ORDER BY bill_gender, ship_gender, rn
