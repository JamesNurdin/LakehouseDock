WITH sales_returns AS (
    SELECT
        cc.cc_division_name AS division,
        r.r_reason_desc   AS reason_desc,
        td.t_sub_shift    AS sub_shift,
        SUM(cs.cs_net_profit)      AS total_profit,
        SUM(wr.wr_net_loss)        AS total_loss,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        COUNT(*)                    AS return_count
    FROM catalog_sales cs
    JOIN call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w          ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td          ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN web_returns wr      ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp         ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r            ON wr.wr_reason_sk = r.r_reason_sk
    WHERE cc.cc_division_name IN ('able', 'anti')
      AND td.t_sub_shift = 'morning'
      AND wp.wp_image_count > 3
    GROUP BY cc.cc_division_name, r.r_reason_desc, td.t_sub_shift
)
SELECT
    division,
    reason_desc,
    sub_shift,
    total_profit,
    total_loss,
    total_profit - total_loss AS net_total,
    num_orders,
    return_count
FROM sales_returns
WHERE (total_profit - total_loss) > 10000
ORDER BY net_total DESC
LIMIT 100
