WITH base_aggregates AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        cp.cp_department,
        td.t_shift,
        SUM(cs.cs_ext_sales_price) AS total_cs_sales,
        SUM(ws.ws_ext_sales_price) AS total_ws_sales,
        SUM(ss.ss_ext_sales_price) AS total_ss_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory_on_hand
    FROM
        time_dim td
        JOIN store_sales ss
            ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN catalog_sales cs
            ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN catalog_returns cr
            ON cr.cr_returned_time_sk = td.t_time_sk
            AND cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
            AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN web_sales ws
            ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN warehouse w
            ON w.w_warehouse_sk = cs.cs_warehouse_sk
            AND w.w_warehouse_sk = cr.cr_warehouse_sk
            AND w.w_warehouse_sk = ws.ws_warehouse_sk
        LEFT JOIN inventory inv
            ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        cs.cs_ext_tax > 100
        AND ws.ws_ext_tax > 50
        AND ss.ss_ext_tax BETWEEN 10 AND 500
        AND td.t_shift = 'first'
        AND w.w_gmt_offset = -5.00
        AND cp.cp_type = 'PROMO'
        AND w.w_warehouse_name LIKE '%effectiv%'
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_name,
        cp.cp_department,
        td.t_shift
)
SELECT
    ba.w_warehouse_name,
    ba.cp_department,
    ba.t_shift,
    ba.total_cs_sales,
    ba.total_ws_sales,
    ba.total_ss_sales,
    ba.total_returns,
    (ba.total_cs_sales + ba.total_ws_sales + ba.total_ss_sales - ba.total_returns) AS net_sales,
    AVG(ba.total_cs_sales + ba.total_ws_sales + ba.total_ss_sales - ba.total_returns) OVER () AS avg_net_sales_all,
    RANK() OVER (ORDER BY (ba.total_cs_sales + ba.total_ws_sales + ba.total_ss_sales - ba.total_returns) DESC) AS sales_rank,
    (SELECT COUNT(DISTINCT cp2.cp_department)
       FROM catalog_page cp2
       WHERE cp2.cp_type = 'PROMO') AS distinct_promo_depts,
    ba.total_inventory_on_hand
FROM
    base_aggregates ba
WHERE
    (ba.total_cs_sales + ba.total_ws_sales + ba.total_ss_sales - ba.total_returns) > (
        SELECT AVG(total_cs_sales + total_ws_sales + total_ss_sales - total_returns)
        FROM base_aggregates
    )
ORDER BY
    net_sales DESC
LIMIT 100
