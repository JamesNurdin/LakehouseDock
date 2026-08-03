WITH sales_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cc.cc_division_name,
        i.i_brand,
        i.i_item_sk,
        sm.sm_ship_mode_id,
        r.r_reason_desc,
        td.t_hour,
        cr.cr_return_amount,
        wr.wr_return_amt
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
                              AND cs.cs_item_sk = cr.cr_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                         AND wr.wr_returned_time_sk = td.t_time_sk
    WHERE cc.cc_employees > 4000000
      AND cc.cc_division_name = 'anti'
      AND i.i_brand = 'BrandA'
      AND sm.sm_ship_mode_id = 'AAAAAAAABAAAAAAA'
      AND r.r_reason_desc = 'Customer Not Satisfied'
      AND cs.cs_quantity > (SELECT avg(cs2.cs_quantity) FROM catalog_sales cs2)
)
SELECT
    sb.cc_division_name,
    sb.i_brand,
    sb.sm_ship_mode_id,
    CASE WHEN sb.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
    COUNT(DISTINCT sb.cs_order_number) AS orders_cnt,
    SUM(sb.cs_net_paid) AS total_net_paid,
    SUM(sb.cr_return_amount) AS total_return_amount,
    AVG(sb.cs_quantity) AS avg_quantity,
    lr.avg_item_return,
    SUM(CASE WHEN sb.wr_return_amt > 0 THEN 1 ELSE 0 END) AS web_return_cnt
FROM sales_base sb
CROSS JOIN LATERAL (
    SELECT avg(cr2.cr_return_amount) AS avg_item_return
    FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = sb.i_item_sk
) lr
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_order_number = sb.cs_order_number
      AND wr2.wr_return_quantity > 0
      AND wr2.wr_item_sk <> sb.i_item_sk
)
GROUP BY
    sb.cc_division_name,
    sb.i_brand,
    sb.sm_ship_mode_id,
    CASE WHEN sb.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END,
    lr.avg_item_return
LIMIT 100
