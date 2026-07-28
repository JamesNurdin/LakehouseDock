SELECT
    cc.cc_name AS call_center_name,
    i_cr.i_category AS item_category,
    cd_returning_cr.cd_gender AS returning_customer_gender,
    COALESCE(p.p_promo_name, 'No Promotion') AS promo_name,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss,
    AVG(p.p_cost) AS avg_promo_cost
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN item i_cr
    ON cr.cr_item_sk = i_cr.i_item_sk
JOIN customer_demographics cd_refund_cr
    ON cr.cr_refunded_cdemo_sk = cd_refund_cr.cd_demo_sk
JOIN customer_demographics cd_returning_cr
    ON cr.cr_returning_cdemo_sk = cd_returning_cr.cd_demo_sk
LEFT JOIN promotion p
    ON p.p_item_sk = i_cr.i_item_sk
LEFT JOIN promotion p2
    ON p2.p_item_sk = i_cr.i_item_sk
   AND p2.p_discount_active = 'Y'
JOIN web_returns wr
    ON wr.wr_item_sk = i_cr.i_item_sk
JOIN customer_demographics cd_refund_wr
    ON wr.wr_refunded_cdemo_sk = cd_refund_wr.cd_demo_sk
JOIN customer_demographics cd_returning_wr
    ON wr.wr_returning_cdemo_sk = cd_returning_wr.cd_demo_sk
WHERE i_cr.i_wholesale_cost > 5.00
GROUP BY
    cc.cc_name,
    i_cr.i_category,
    cd_returning_cr.cd_gender,
    COALESCE(p.p_promo_name, 'No Promotion')
ORDER BY total_net_loss DESC
LIMIT 100
