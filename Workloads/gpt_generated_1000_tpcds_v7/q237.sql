WITH joined AS (
    SELECT
        d.d_date,
        w.w_warehouse_name,
        cs.cs_net_paid,
        sr.sr_return_amt,
        ws.ws_net_paid,
        i.inv_quantity_on_hand,
        cr.cr_reason_sk,
        r.r_reason_desc,
        t.t_minute,
        wp.wp_autogen_flag,
        sr.sr_store_credit,
        cs.cs_quantity
    FROM tpcds.date_dim d
    LEFT JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN tpcds.call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN tpcds.warehouse w
        ON w.w_warehouse_sk = cs.cs_warehouse_sk
    LEFT JOIN tpcds.customer c
        ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN tpcds.customer_address ca
        ON ca.ca_address_sk = cs.cs_bill_addr_sk
    LEFT JOIN tpcds.customer_demographics cd
        ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    LEFT JOIN tpcds.reason r
        ON r.r_reason_sk = cr.cr_reason_sk
    LEFT JOIN tpcds.time_dim t
        ON t.t_time_sk = cs.cs_sold_time_sk
    LEFT JOIN tpcds.web_page wp
        ON wp.wp_web_page_sk = ws.ws_web_page_sk
    WHERE d.d_year = 2001
      AND t.t_minute IN (8, 13)
      AND wp.wp_autogen_flag = 'Y'
      AND sr.sr_store_credit > 10
      AND cs.cs_quantity > 1
),
agg AS (
    SELECT
        d_date,
        w_warehouse_name,
        SUM(cs_net_paid) AS total_sales,
        SUM(sr_return_amt) AS total_store_returns,
        SUM(ws_net_paid) AS total_web_sales,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM joined
    GROUP BY d_date, w_warehouse_name
)
SELECT
    d_date,
    w_warehouse_name,
    total_sales,
    total_store_returns,
    total_web_sales,
    total_inventory,
    RANK() OVER (PARTITION BY d_date ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY d_date DESC, sales_rank
LIMIT 100
