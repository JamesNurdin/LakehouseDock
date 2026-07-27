WITH filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        p.p_promo_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cr.cr_return_amount,
        cr.cr_return_tax,
        ws.ws_ext_ship_cost,
        ws.ws_warehouse_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN tpcds.web_sales ws
        ON ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_item_sk = cs.cs_item_sk
    WHERE p.p_discount_active = 'Y'
      AND cd.cd_purchase_estimate >= 3000
      AND cr.cr_return_amount > 500
      AND ws.ws_ext_ship_cost < 2000
)
SELECT
    p_promo_name,
    cd_gender,
    cd_marital_status,
    SUM(cs_quantity) AS total_quantity,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(cr_return_amount) AS avg_return_amount,
    MIN(ws_ext_ship_cost) AS min_ship_cost,
    MAX(ws_ext_ship_cost) AS max_ship_cost
FROM filtered
GROUP BY p_promo_name, cd_gender, cd_marital_status
HAVING SUM(cs_net_paid) > 100000
   AND COUNT(DISTINCT cs_order_number) >= 10
ORDER BY total_net_paid DESC
LIMIT 100
