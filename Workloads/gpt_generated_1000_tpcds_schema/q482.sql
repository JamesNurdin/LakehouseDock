WITH intersect_keys AS (
    SELECT cp.cp_catalog_page_sk
    FROM catalog_page cp
    WHERE cp.cp_catalog_number = 9
    INTERSECT
    SELECT cr.cr_catalog_page_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 5
),
base AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        s.s_state,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        d_ret.d_date AS return_date,
        d_ws_sold.d_date AS sold_date,
        cr.cr_return_amount,
        ws.ws_net_profit,
        ws.ws_order_number,
        inv.inv_quantity_on_hand,
        sm.sm_type
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    LEFT JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
       AND inv.inv_date_sk = d_ret.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
       AND ws.ws_sold_date_sk = d_ret.d_date_sk
    LEFT JOIN date_dim d_ws_sold
        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN date_dim d_wr_ret
        ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
    WHERE
        d_ret.d_year = 2001
        AND cp.cp_department = 'Books'
        AND sm.sm_type = 'AIR'
        AND cd_refunded.cd_education_status = 'Advanced Degree'
        AND s.s_state = 'CA'
        AND inv.inv_quantity_on_hand > 100
        AND cp.cp_catalog_page_sk NOT IN (
            SELECT cr2.cr_catalog_page_sk
            FROM catalog_returns cr2
            WHERE cr2.cr_return_amount > 5000
        )
        AND cp.cp_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM intersect_keys)
),
agg AS (
    SELECT
        b.cp_catalog_page_sk,
        b.cp_department,
        b.s_state,
        b.w_warehouse_name,
        b.w_warehouse_sk,
        COUNT(DISTINCT b.ws_order_number) AS order_cnt,
        SUM(b.cr_return_amount) AS total_return_amount,
        SUM(b.ws_net_profit) AS total_ws_net_profit,
        MIN(b.return_date) AS first_return_date
    FROM base b
    GROUP BY
        b.cp_catalog_page_sk,
        b.cp_department,
        b.s_state,
        b.w_warehouse_name,
        b.w_warehouse_sk
)
SELECT
    a.cp_catalog_page_sk,
    a.cp_department,
    a.s_state,
    a.w_warehouse_name,
    a.order_cnt,
    a.total_return_amount,
    a.total_ws_net_profit,
    a.first_return_date,
    (
        SELECT SUM(inv4.inv_quantity_on_hand)
        FROM inventory inv4
        WHERE inv4.inv_warehouse_sk = a.w_warehouse_sk
    ) AS total_warehouse_inventory,
    ROW_NUMBER() OVER (PARTITION BY a.s_state ORDER BY a.total_ws_net_profit DESC) AS state_rank
FROM agg a
ORDER BY a.total_ws_net_profit DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
