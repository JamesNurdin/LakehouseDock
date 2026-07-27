WITH joined_data AS (
    SELECT
        d.d_year,
        d.d_date,
        cc.cc_call_center_id,
        cc.cc_city,
        cs.cs_order_number,
        cs.cs_net_paid_inc_tax,
        cs.cs_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss AS wr_net_loss,
        r.r_reason_desc,
        sm.sm_type,
        w.w_warehouse_name,
        w.w_state,
        s.s_store_id,
        s.s_state,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_order_number = cs.cs_order_number
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cs.cs_net_paid_inc_tax > 500
      AND w.w_state = 'CA'
      AND cc.cc_city = 'San Francisco'
      AND r.r_reason_desc LIKE '%color%'
      AND s.s_state = 'CA'
),
agg_by_store_reason AS (
    SELECT
        s_store_id,
        r_reason_desc,
        SUM(cs_net_paid_inc_tax) AS sales,
        SUM(COALESCE(cr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS loss
    FROM joined_data
    GROUP BY s_store_id, r_reason_desc
),
store_summary AS (
    SELECT
        s_store_id,
        AVG(sales) AS avg_sales,
        SUM(loss) AS total_loss
    FROM agg_by_store_reason
    GROUP BY s_store_id
    HAVING AVG(sales) > 2000
)
SELECT
    s_store_id,
    avg_sales,
    total_loss,
    ROW_NUMBER() OVER (ORDER BY avg_sales DESC) AS sales_rank
FROM store_summary
ORDER BY avg_sales DESC
