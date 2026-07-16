WITH ws_agg AS (
    SELECT
        ca.ca_state,
        ws.ws_sold_date_sk AS sale_date_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
      AND p.p_discount_active = 'Y'
    GROUP BY ca.ca_state, ws.ws_sold_date_sk
),
cr_agg AS (
    SELECT
        ca.ca_state,
        cr.cr_returned_date_sk AS return_date_sk,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
      AND cr.cr_warehouse_sk = 1
      AND cr.cr_item_sk IN (235196, 207490)
    GROUP BY ca.ca_state, cr.cr_returned_date_sk
)
SELECT
    ws.ca_state,
    ws.sale_date_sk,
    ws.total_sales,
    cr.total_return_loss,
    ws.total_profit,
    ws.total_discount,
    (ws.total_sales - COALESCE(cr.total_return_loss, 0)) AS net_revenue,
    RANK() OVER (PARTITION BY ws.ca_state ORDER BY (ws.total_sales - COALESCE(cr.total_return_loss, 0)) DESC) AS revenue_rank
FROM ws_agg ws
LEFT JOIN cr_agg cr
    ON ws.ca_state = cr.ca_state
   AND ws.sale_date_sk = cr.return_date_sk
ORDER BY net_revenue DESC
LIMIT 100
