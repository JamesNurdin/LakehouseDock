SELECT
    wh.w_state,
    wh.w_city,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_return_customers,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_sales_customers,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    SUM(ws.ws_ext_discount_amt) AS total_discount_given,
    AVG(ws.ws_quantity) AS avg_quantity_per_sale,
    (SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss)) AS net_contribution
FROM
    catalog_returns cr
    INNER JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
    INNER JOIN web_sales ws ON ws.ws_warehouse_sk = wh.w_warehouse_sk
WHERE
    cr.cr_returning_customer_sk IN (6114601, 7882809, 502311)
    AND cr.cr_item_sk = 48118
    AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451200
    AND ws.ws_ext_discount_amt > 0
GROUP BY
    wh.w_state,
    wh.w_city
HAVING
    (SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss)) > 5000
ORDER BY
    net_contribution DESC
LIMIT 50
