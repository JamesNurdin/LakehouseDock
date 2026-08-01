WITH
    all_store_orders AS (
        SELECT ss.ss_ticket_number AS order_id
        FROM store_sales ss
        WHERE ss.ss_quantity > 2
    ),
    returned_orders AS (
        SELECT cr.cr_order_number AS order_id
        FROM catalog_returns cr
        WHERE cr.cr_return_quantity > 0
    ),
    web_orders AS (
        SELECT ws.ws_order_number AS order_id
        FROM web_sales ws
        WHERE ws.ws_quantity > 1
    ),
    non_returned_store_orders AS (
        SELECT order_id FROM all_store_orders
        EXCEPT
        SELECT order_id FROM returned_orders
    ),
    common_orders AS (
        SELECT order_id FROM non_returned_store_orders
        INTERSECT
        SELECT order_id FROM web_orders
    )
SELECT
    d.d_year,
    cd.cd_gender,
    COUNT(DISTINCT co.order_id) AS common_order_cnt,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(ss.ss_quantity) AS min_store_qty,
    MAX(ws.ws_quantity) AS max_web_qty
FROM common_orders co
JOIN store_sales ss ON ss.ss_ticket_number = co.order_id
JOIN web_sales ws ON ws.ws_order_number = co.order_id
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = co.order_id
   AND cr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND cd.cd_gender = 'F'
  AND d.d_dom = 15
  AND ss.ss_net_paid > 20
  AND ws.ws_net_paid > 20
  AND (cr.cr_return_amount IS NULL OR cr.cr_return_amount > 10)
GROUP BY d.d_year, cd.cd_gender
ORDER BY total_store_net_paid DESC
LIMIT 100
