WITH inv_agg AS (
    SELECT
        i.inv_warehouse_sk AS w_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory i
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY i.inv_warehouse_sk
),
agg_metrics AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cc.cc_name AS call_center_name,
        w.w_warehouse_name,
        r.r_reason_desc,
        t.t_hour,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        CASE
            WHEN SUM(cr.cr_net_loss) > 0 THEN 'Return Loss'
            ELSE 'No Return Loss'
        END AS return_loss_flag,
        inv_agg.total_quantity_on_hand
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = t.t_time_sk
        AND ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_cdemo_sk = cd.cd_demo_sk
        AND ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    JOIN inv_agg
        ON w.w_warehouse_sk = inv_agg.w_warehouse_sk
    WHERE
        cc.cc_state = 'CA'
        AND w.w_state = 'CA'
        AND t.t_hour BETWEEN 9 AND 17
        AND r.r_reason_desc IN ('Did not like the model', 'Stopped working')
        AND cs.cs_quantity > 0
        AND c.c_birth_year > 1970
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cs.cs_order_number
              AND cr2.cr_net_loss > 100
        )
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cc.cc_name,
        w.w_warehouse_name,
        r.r_reason_desc,
        t.t_hour,
        inv_agg.total_quantity_on_hand
    HAVING
        SUM(cs.cs_net_paid) > 1000
)
SELECT
    am.c_customer_id,
    am.c_first_name,
    am.c_last_name,
    am.call_center_name,
    am.w_warehouse_name,
    am.r_reason_desc,
    am.t_hour,
    am.total_sales,
    am.total_return_loss,
    am.total_store_sales,
    am.total_web_return_loss,
    am.return_loss_flag,
    am.total_quantity_on_hand,
    RANK() OVER (PARTITION BY am.w_warehouse_name ORDER BY am.total_sales DESC) AS sales_rank_by_warehouse
FROM agg_metrics am
ORDER BY am.total_sales DESC
LIMIT 100
