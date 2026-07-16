SELECT
    p.p_promo_sk,
    p.p_promo_name,
    w.w_state,
    cd.cd_gender,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
    SUM(cs.cs_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0)) AS net_profit_after_returns,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_per_order,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_quantity_returned,
    CASE WHEN SUM(cs.cs_quantity) > 0 THEN
        SUM(COALESCE(cr.cr_return_quantity, 0)) * 1.0 / SUM(cs.cs_quantity)
    ELSE 0 END AS return_rate
FROM
    catalog_sales cs
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
WHERE
    cs.cs_quantity > 0
    AND cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
GROUP BY
    p.p_promo_sk,
    p.p_promo_name,
    w.w_state,
    cd.cd_gender
HAVING
    SUM(cs.cs_net_profit) > 1000
    AND SUM(cs.cs_quantity) > 10
ORDER BY
    net_profit_after_returns DESC
LIMIT 100
