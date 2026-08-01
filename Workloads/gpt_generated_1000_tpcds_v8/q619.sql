WITH
    cr_base AS (
        SELECT
            cr.cr_order_number,
            cr.cr_refunded_customer_sk AS customer_sk,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            cr.cr_return_ship_cost,
            cr.cr_net_loss,
            cr.cr_reason_sk,
            cr.cr_returned_date_sk,
            i.i_item_sk,
            i.i_category,
            i.i_current_price,
            r.r_reason_id,
            r.r_reason_desc,
            ca.ca_state,
            inv.inv_quantity_on_hand,
            c.c_customer_id
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        WHERE cr.cr_return_ship_cost > 100
          AND cr.cr_return_quantity >= 1
          AND i.i_current_price BETWEEN 10 AND 500
          AND r.r_reason_id LIKE 'AAAAAAA%'
          AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
    ),
    wr_base AS (
        SELECT
            wr.wr_order_number,
            wr.wr_refunded_customer_sk AS customer_sk,
            wr.wr_return_quantity,
            wr.wr_return_amt AS return_amount,
            wr.wr_return_ship_cost AS ship_cost,
            wr.wr_net_loss,
            wr.wr_reason_sk,
            wr.wr_returned_date_sk,
            i.i_item_sk,
            i.i_category,
            i.i_current_price,
            r.r_reason_id,
            r.r_reason_desc,
            ca.ca_state,
            inv.inv_quantity_on_hand,
            c.c_customer_id
        FROM web_returns wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        WHERE wr.wr_return_ship_cost > 100
          AND wr.wr_return_quantity >= 1
          AND i.i_current_price BETWEEN 10 AND 500
          AND r.r_reason_id LIKE 'AAAAAAA%'
          AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2459999
    ),
    combined AS (
        SELECT
            COALESCE(cr.cr_order_number, wr.wr_order_number)      AS order_number,
            COALESCE(cr.customer_sk, wr.customer_sk)              AS customer_sk,
            COALESCE(cr.cr_return_quantity, wr.wr_return_quantity) AS return_quantity,
            COALESCE(cr.cr_return_amount, wr.return_amount)       AS return_amount,
            COALESCE(cr.cr_return_ship_cost, wr.ship_cost)        AS ship_cost,
            COALESCE(cr.cr_net_loss, wr.wr_net_loss)              AS net_loss,
            COALESCE(cr.i_category, wr.i_category)                AS category,
            COALESCE(cr.r_reason_id, wr.r_reason_id)              AS reason_id,
            COALESCE(cr.ca_state, wr.ca_state)                    AS state
        FROM cr_base cr
        FULL OUTER JOIN wr_base wr
          ON cr.cr_order_number = wr.wr_order_number
    ),
    agg AS (
        SELECT
            customer_sk,
            category,
            reason_id,
            SUM(return_quantity) AS total_qty,
            SUM(return_amount)   AS total_amount,
            SUM(net_loss)        AS total_net_loss,
            COUNT(*)             AS cnt
        FROM combined
        GROUP BY GROUPING SETS (
            (customer_sk, category, reason_id),
            (category, reason_id),
            (reason_id)
        )
    ),
    excluded_orders AS (
        SELECT cr_order_number AS order_number FROM catalog_returns
        EXCEPT
        SELECT wr_order_number FROM web_returns
    ),
    intersect_customers AS (
        SELECT cr_refunded_customer_sk AS customer_sk FROM catalog_returns
        INTERSECT
        SELECT wr_refunded_customer_sk FROM web_returns
    )
SELECT
    a.customer_sk,
    a.category,
    a.reason_id,
    a.total_qty,
    a.total_amount,
    a.total_net_loss,
    a.cnt,
    SUM(a.total_net_loss) OVER (PARTITION BY a.category ORDER BY a.total_qty DESC ROWS UNBOUNDED PRECEDING) AS running_net_loss,
    ROW_NUMBER() OVER (PARTITION BY a.category ORDER BY a.total_net_loss DESC) AS rank_in_category,
    (SELECT COUNT(*) FROM excluded_orders)      AS excluded_order_cnt,
    (SELECT COUNT(*) FROM intersect_customers)  AS intersect_customer_cnt
FROM agg a
WHERE a.total_qty > 0
  AND a.total_amount > 0
  AND a.total_net_loss > 0
  AND a.cnt >= 2
  AND a.category IS NOT NULL
ORDER BY a.total_net_loss DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
