/* Goal: Analyze combined returns and sales performance by hour and warehouse for orders with high‑value returns, filtering by specific shipping and return criteria, and focusing on orders that appear only in returns (not in high‑quantity sales) and store tickets that satisfy intersected conditions. */
WITH base AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_order_number,
        cr.cr_warehouse_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_net_loss,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_amt_inc_tax,
        sr.sr_fee,
        sr.sr_return_ship_cost,
        sr.sr_refunded_cash,
        sr.sr_net_loss,
        sr.sr_ticket_number,
        td.t_time_sk,
        td.t_hour,
        td.t_am_pm,
        td.t_meal_time
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
        AND cs.cs_sold_time_sk = td.t_time_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
    WHERE cr.cr_warehouse_sk = 5
      AND cs.cs_ship_hdemo_sk = 5775
      AND cs.cs_sales_price > 100
      AND sr.sr_reason_sk IN (26, 34)
),

diff_orders AS (
    SELECT DISTINCT cr_order_number
    FROM catalog_returns
    WHERE cr_return_amount > 2000
    EXCEPT
    SELECT DISTINCT cs_order_number
    FROM catalog_sales
    WHERE cs_quantity > 5
),

intersect_tickets AS (
    SELECT DISTINCT sr_ticket_number
    FROM store_returns
    WHERE sr_return_amt > 150
    INTERSECT
    SELECT DISTINCT sr_ticket_number
    FROM store_returns
    WHERE sr_return_tax > 10
)

SELECT
    base.t_hour,
    base.t_am_pm,
    base.cr_warehouse_sk,
    COUNT(DISTINCT base.cr_order_number) AS distinct_orders,
    SUM(base.cr_return_amount) AS total_return_amount,
    AVG(base.cs_sales_price) AS avg_sales_price,
    SUM(base.cs_net_profit) AS total_net_profit,
    MIN(base.sr_return_amt) AS min_store_return_amount,
    MAX(base.sr_return_amt) AS max_store_return_amount
FROM base
WHERE base.cr_order_number IN (SELECT cr_order_number FROM diff_orders)
  AND base.sr_ticket_number IN (SELECT sr_ticket_number FROM intersect_tickets)
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = base.cr_order_number
          AND cr2.cr_return_amount > 500
    )
GROUP BY
    base.t_hour,
    base.t_am_pm,
    base.cr_warehouse_sk
ORDER BY
    total_return_amount DESC,
    base.t_hour ASC
LIMIT 100
