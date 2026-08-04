WITH item_info AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_product_name,
        i_current_price,
        i_wholesale_cost,
        ARRAY[i_current_price, i_wholesale_cost] AS price_array
    FROM tpcds.item
)
SELECT
    ii.i_item_id,
    ii.i_product_name,
    r.r_reason_desc,
    sm.sm_type,
    COUNT(DISTINCT cr.cr_order_number) AS cnt_return_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_paid) AS total_sales,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    AVG(price) AS avg_price_component,
    (SELECT MAX(cr2.cr_return_amount)
     FROM tpcds.catalog_returns cr2
     WHERE cr2.cr_item_sk = cr.cr_item_sk) AS max_item_return_amount
FROM tpcds.catalog_returns cr
JOIN item_info ii
  ON cr.cr_item_sk = ii.i_item_sk
CROSS JOIN UNNEST(ii.price_array) AS t(price)
JOIN tpcds.reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.customer c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.web_sales ws
  ON ws.ws_item_sk = ii.i_item_sk
JOIN tpcds.web_returns wr
  ON wr.wr_item_sk = ii.i_item_sk
 AND wr.wr_order_number = ws.ws_order_number
WHERE
    ii.i_current_price > 50.00
    AND r.r_reason_desc = 'Damaged'
    AND sm.sm_type = 'AIR'
    AND hd.hd_buy_potential = '5001-10000'
    AND ws.ws_wholesale_cost BETWEEN 10 AND 60
GROUP BY
    ii.i_item_id,
    ii.i_product_name,
    r.r_reason_desc,
    sm.sm_type,
    cr.cr_item_sk
HAVING
    SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
