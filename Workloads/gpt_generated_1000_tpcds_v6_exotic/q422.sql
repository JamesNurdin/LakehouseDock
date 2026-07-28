WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_promo_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk
    FROM catalog_sales cs
)
SELECT
    w_sales.w_city AS sales_city,
    w_return.w_city AS return_city,
    p.p_promo_name,
    cd_bill.cd_credit_rating AS bill_credit_rating,
    cd_ship.cd_credit_rating AS ship_credit_rating,
    SUM(s.cs_quantity) AS total_quantity,
    SUM(s.cs_net_profit) AS total_profit,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    CASE
        WHEN SUM(s.cs_net_profit) > 1000 THEN 'HIGH'
        ELSE 'LOW'
    END AS profit_category,
    (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS avg_active_promo_cost
FROM sales_agg s
JOIN catalog_returns cr
    ON cr.cr_order_number = s.cs_order_number
JOIN customer_demographics cd_bill
    ON s.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill
    ON s.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship
    ON s.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_address ca_ship
    ON s.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN warehouse w_sales
    ON s.cs_warehouse_sk = w_sales.w_warehouse_sk
JOIN promotion p
    ON s.cs_promo_sk = p.p_promo_sk
JOIN warehouse w_return
    ON cr.cr_warehouse_sk = w_return.w_warehouse_sk
JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_demographics cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
WHERE p.p_channel_catalog = 'Y'
GROUP BY
    w_sales.w_city,
    w_return.w_city,
    p.p_promo_name,
    cd_bill.cd_credit_rating,
    cd_ship.cd_credit_rating
HAVING SUM(s.cs_net_profit) > 500
ORDER BY total_profit DESC
LIMIT 100
