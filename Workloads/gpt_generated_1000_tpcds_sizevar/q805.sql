WITH
/* Fact sales joined to dimensional tables */
sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_ship_cost,
        cs.cs_net_paid,
        cc.cc_state,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name,
        w.w_street_type
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND w.w_street_type IN ('Drive', 'Parkway')
      AND cs.cs_ext_ship_cost > 1000
),
/* Catalog returns linked to reason and dimensional tables */
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 500
      AND r.r_reason_desc LIKE '%defect%'
),
/* Inventory filtered by low stock */
inventory_cte AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE inv.inv_quantity_on_hand < 100
),
/* Web returns linked to reason */
web_ret AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_refunded_cash,
        r.r_reason_desc AS web_reason_desc
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_refunded_cash BETWEEN 100 AND 500
),
/* Set‑operation helpers */
order_intersect AS (
    SELECT order_num FROM (
        SELECT cs_order_number AS order_num FROM sales WHERE cs_quantity > 10
        INTERSECT
        SELECT cr_order_number FROM returns WHERE cr_return_quantity > 2
    )
),
order_exclude AS (
    SELECT cs_order_number FROM sales
    EXCEPT
    SELECT cr_order_number FROM returns
),
/* Ranked aggregation */
ranked AS (
    SELECT
        s.w_warehouse_name,
        s.ship_mode_type,
        SUM(s.cs_net_paid)                         AS total_sales,
        SUM(r.cr_return_amount)                    AS total_returns,
        SUM(wr.wr_return_amt)                      AS total_web_returns,
        AVG(s.cs_ext_ship_cost)                    AS avg_ship_cost,
        COUNT(DISTINCT s.cs_order_number)          AS uniq_orders,
        MIN(s.cs_quantity)                         AS min_quantity,
        MAX(s.cs_quantity)                         AS max_quantity,
        ROW_NUMBER() OVER (PARTITION BY s.w_warehouse_name ORDER BY SUM(s.cs_net_paid) DESC) AS rn
    FROM sales s
    JOIN returns r      ON s.cs_order_number = r.cr_order_number
    JOIN web_ret wr      ON s.cs_order_number = wr.wr_order_number
    JOIN inventory_cte i ON s.cs_item_sk = i.inv_item_sk
                         AND s.w_warehouse_name = (SELECT w.w_warehouse_name FROM warehouse w WHERE w.w_warehouse_sk = i.inv_warehouse_sk)
    WHERE EXISTS (
            SELECT 1 FROM catalog_returns cr2
            WHERE cr2.cr_order_number = s.cs_order_number
              AND cr2.cr_return_quantity > 2
          )
      AND s.cs_order_number IN (SELECT order_num FROM order_intersect)
      AND s.cs_order_number NOT IN (SELECT cs_order_number FROM order_exclude)
    GROUP BY s.w_warehouse_name, s.ship_mode_type
    HAVING SUM(s.cs_net_paid) > (SELECT AVG(cs_net_paid) FROM sales)
)
SELECT
    w_warehouse_name,
    ship_mode_type,
    total_sales,
    total_returns,
    total_web_returns,
    avg_ship_cost,
    uniq_orders,
    min_quantity,
    max_quantity
FROM ranked
WHERE rn <= 5
ORDER BY total_sales DESC
LIMIT 100
