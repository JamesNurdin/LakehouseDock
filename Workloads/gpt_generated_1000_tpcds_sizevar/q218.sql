WITH filtered_returns AS (
    SELECT
        cr.cr_order_number AS order_number,
        i.i_item_id,
        i.i_category,
        t.t_hour,
        cd.cd_credit_rating,
        ca.ca_state,
        cr.cr_return_amount,
        CASE WHEN cr.cr_net_loss > 500 THEN 'High' ELSE 'Low' END AS loss_flag,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY cr.cr_return_amount DESC) AS rn
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE i.i_current_price BETWEEN 20 AND 100
      AND t.t_hour BETWEEN 9 AND 17
      AND cd.cd_credit_rating = 'Good'
      AND ca.ca_state IN ('CA', 'TX')
      AND cr.cr_return_amount > 0
      AND cr.cr_net_loss > 0
),
filtered_sales AS (
    SELECT
        ws.ws_order_number AS order_number,
        i.i_item_id,
        i.i_category,
        t.t_hour,
        cd.cd_credit_rating,
        ca.ca_state,
        ws.ws_ext_sales_price AS cr_return_amount,
        CASE WHEN ws.ws_net_profit > 500 THEN 'High' ELSE 'Low' END AS loss_flag,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ws.ws_ext_sales_price DESC) AS rn
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE i.i_current_price BETWEEN 20 AND 100
      AND t.t_hour BETWEEN 9 AND 17
      AND cd.cd_credit_rating = 'Good'
      AND ca.ca_state IN ('CA', 'TX')
      AND ws.ws_ext_sales_price > 0
      AND ws.ws_net_profit > 0
)
SELECT *
FROM filtered_returns
EXCEPT
SELECT *
FROM filtered_sales
ORDER BY rn
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
