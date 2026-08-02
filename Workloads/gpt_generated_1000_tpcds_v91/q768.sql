WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number
    FROM store_sales ss
),
sales_bucket AS (
    SELECT
        bs.*,
        CASE WHEN bs.ss_quantity > 10 THEN 'High' ELSE 'Low' END AS quantity_bucket
    FROM base_sales bs
)
SELECT
    d.d_year,
    i.i_category,
    sb.quantity_bucket,
    COUNT(DISTINCT sb.ss_ticket_number) AS order_cnt,
    SUM(sb.ss_ext_sales_price) AS total_sales,
    AVG(sb.ss_net_profit) AS avg_profit,
    COUNT(DISTINCT tags.tag) AS distinct_tags,
    MAX(r.r_reason_desc) AS reason_desc,
    (SELECT COUNT(*) FROM store) AS total_store_cnt
FROM sales_bucket sb
JOIN date_dim d
    ON sb.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON sb.ss_sold_time_sk = t.t_time_sk
JOIN item i
    ON sb.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd_sales
    ON sb.ss_cdemo_sk = cd_sales.cd_demo_sk
JOIN household_demographics hd_sales
    ON sb.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN store s
    ON sb.ss_store_sk = s.s_store_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
   AND cr.cr_returned_time_sk = t.t_time_sk
   AND cr.cr_item_sk = i.i_item_sk
LEFT JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
LEFT JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
LEFT JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_sold_time_sk = t.t_time_sk
   AND ws.ws_item_sk = i.i_item_sk
   AND ws.ws_bill_cdemo_sk = cd_sales.cd_demo_sk
   AND ws.ws_bill_hdemo_sk = hd_sales.hd_demo_sk
LEFT JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
CROSS JOIN UNNEST(ARRAY[1,2,3]) AS u(dummy_val)
LEFT JOIN UNNEST(ARRAY[i.i_brand, i.i_category]) AS tags(tag) ON TRUE
WHERE sb.ss_sold_date_sk NOT IN (SELECT cr2.cr_returned_date_sk FROM catalog_returns cr2)
GROUP BY GROUPING SETS (
    (d.d_year, i.i_category, sb.quantity_bucket),
    (d.d_year, i.i_category),
    (d.d_year),
    ()
)
ORDER BY d.d_year DESC, i.i_category, total_sales DESC
LIMIT 100
