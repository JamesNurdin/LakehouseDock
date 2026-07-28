WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        i.i_item_id,
        i.i_item_desc,
        w.w_warehouse_id,
        w.w_city,
        cc.cc_name,
        we.web_name,
        s.s_store_name,
        cd.cd_education_status,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        ws.ws_net_paid,
        ws.ws_quantity,
        inv.inv_quantity_on_hand
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND w.w_state = 'CA'
      AND cc.cc_state = 'TX'
      AND inv.inv_quantity_on_hand > 100
      AND cd.cd_education_status = 'Advanced Degree'
),
agg AS (
    SELECT
        i_item_id,
        w_warehouse_id,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(ws_net_paid) AS total_sales,
        AVG(inv_quantity_on_hand) AS avg_inv_qty,
        COUNT(DISTINCT d_date) AS days_sold
    FROM base
    GROUP BY i_item_id, w_warehouse_id
    HAVING SUM(cr_return_amount) > 0
)
SELECT
    i_item_id,
    w_warehouse_id,
    total_return_amount,
    total_sales,
    total_return_amount / NULLIF(total_sales, 0) AS ratio
FROM agg
WHERE total_return_amount / NULLIF(total_sales, 0) > 0.05
ORDER BY ratio DESC
LIMIT 10
