WITH base_all AS (
    SELECT
        s.s_store_name,
        t_sales.t_hour AS hour_of_day,
        ss.ss_customer_sk,
        w1.w_warehouse_sk   AS catalog_warehouse_sk,
        w2.w_warehouse_sk   AS web_warehouse_sk,
        SUM(ss.ss_ext_sales_price)                     AS store_sales_total,
        COALESCE(SUM(sr.sr_return_amt), 0)             AS store_returns_total,
        COALESCE(SUM(cr.cr_return_amount), 0)          AS catalog_returns_total,
        COALESCE(SUM(ws.ws_ext_sales_price), 0)        AS web_sales_total,
        COALESCE(SUM(wr.wr_return_amt), 0)             AS web_returns_total,
        (
            SELECT SUM(inv2.inv_quantity_on_hand)
            FROM inventory inv2
            WHERE inv2.inv_warehouse_sk = w1.w_warehouse_sk
        )                                               AS catalog_warehouse_inventory,
        (
            SELECT SUM(ws3.ws_ext_sales_price)
            FROM web_sales ws3
            WHERE ws3.ws_bill_customer_sk = ss.ss_customer_sk
        )                                               AS customer_total_web_sales
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t_sales
        ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN household_demographics hd_store
        ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
    JOIN customer_address ca_store
        ON ss.ss_addr_sk = ca_store.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_return_time_sk = t_sales.t_time_sk
    LEFT JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = t_sales.t_time_sk
    LEFT JOIN warehouse w1
        ON cr.cr_warehouse_sk = w1.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_warehouse_sk = w1.w_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_time_sk = t_sales.t_time_sk
        AND ws.ws_bill_hdemo_sk = hd_store.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca_store.ca_address_sk
    LEFT JOIN warehouse w2
        ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_time_sk = t_sales.t_time_sk
    GROUP BY
        s.s_store_name,
        t_sales.t_hour,
        ss.ss_customer_sk,
        w1.w_warehouse_sk,
        w2.w_warehouse_sk
),
base_filtered AS (
    SELECT
        s.s_store_name,
        t_sales.t_hour AS hour_of_day,
        ss.ss_customer_sk,
        w1.w_warehouse_sk   AS catalog_warehouse_sk,
        w2.w_warehouse_sk   AS web_warehouse_sk,
        SUM(ss.ss_ext_sales_price)                     AS store_sales_total,
        COALESCE(SUM(sr.sr_return_amt), 0)             AS store_returns_total,
        COALESCE(SUM(cr.cr_return_amount), 0)          AS catalog_returns_total,
        COALESCE(SUM(ws.ws_ext_sales_price), 0)        AS web_sales_total,
        COALESCE(SUM(wr.wr_return_amt), 0)             AS web_returns_total,
        (
            SELECT SUM(inv2.inv_quantity_on_hand)
            FROM inventory inv2
            WHERE inv2.inv_warehouse_sk = w1.w_warehouse_sk
        )                                               AS catalog_warehouse_inventory,
        (
            SELECT SUM(ws3.ws_ext_sales_price)
            FROM web_sales ws3
            WHERE ws3.ws_bill_customer_sk = ss.ss_customer_sk
        )                                               AS customer_total_web_sales
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t_sales
        ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN household_demographics hd_store
        ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
    JOIN customer_address ca_store
        ON ss.ss_addr_sk = ca_store.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_return_time_sk = t_sales.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = t_sales.t_time_sk
        AND cr.cr_reason_sk = 4
    LEFT JOIN warehouse w1
        ON cr.cr_warehouse_sk = w1.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_warehouse_sk = w1.w_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_time_sk = t_sales.t_time_sk
        AND ws.ws_bill_hdemo_sk = hd_store.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca_store.ca_address_sk
    LEFT JOIN warehouse w2
        ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_time_sk = t_sales.t_time_sk
    GROUP BY
        s.s_store_name,
        t_sales.t_hour,
        ss.ss_customer_sk,
        w1.w_warehouse_sk,
        w2.w_warehouse_sk
)
SELECT
    u.s_store_name,
    u.hour_of_day,
    u.store_sales_total,
    u.store_returns_total,
    u.catalog_returns_total,
    u.web_sales_total,
    u.web_returns_total,
    u.catalog_warehouse_inventory,
    u.customer_total_web_sales,
    SUM(u.store_sales_total) OVER (
        PARTITION BY u.s_store_name
        ORDER BY u.hour_of_day
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_store_sales,
    RANK() OVER (
        PARTITION BY u.s_store_name
        ORDER BY u.store_sales_total DESC
    ) AS sales_rank
FROM (
    SELECT * FROM base_all
    UNION
    SELECT * FROM base_filtered
) u
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr_exist
    JOIN store s_exist ON sr_exist.sr_store_sk = s_exist.s_store_sk
    WHERE s_exist.s_store_name = u.s_store_name
      AND sr_exist.sr_return_quantity > 0
)
ORDER BY u.s_store_name, u.hour_of_day
