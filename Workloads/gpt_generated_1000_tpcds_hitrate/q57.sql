WITH sales_agg AS (
    SELECT
        cs_item_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_sold_date_sk,
        cs_order_number,
        cs_promo_sk,
        SUM(cs_net_paid) AS sales_net_paid,
        AVG(cs_sales_price) AS avg_sales_price,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_quantity > 5
    GROUP BY cs_item_sk, cs_ship_mode_sk, cs_warehouse_sk, cs_sold_date_sk, cs_order_number, cs_promo_sk
)
SELECT
    s.s_store_name,
    d_sold.d_year,
    p.p_promo_name,
    r.r_reason_desc,
    sm.sm_type,
    wp.wp_url,
    ws.web_name,
    SUM(sa.sales_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(sa.avg_sales_price) AS avg_sales_price,
    COUNT(DISTINCT sa.cs_order_number) AS distinct_orders,
    lt.avg_ret_amount
FROM sales_agg sa
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = sa.cs_item_sk
   AND cr.cr_order_number = sa.cs_order_number
LEFT JOIN date_dim d_sold
    ON sa.cs_sold_date_sk = d_sold.d_date_sk
LEFT JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN promotion p
    ON sa.cs_promo_sk = p.p_promo_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN ship_mode sm
    ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w
    ON sa.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN date_dim d_web
    ON d_sold.d_date_sk = d_web.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = d_web.d_date_sk
LEFT JOIN date_dim d_site
    ON d_sold.d_date_sk = d_site.d_date_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d_site.d_date_sk
RIGHT OUTER JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
-- LATERAL subquery to get average return amount per reason
LEFT JOIN LATERAL (
    SELECT AVG(cr2.cr_return_amount) AS avg_ret_amount
    FROM catalog_returns cr2
    WHERE cr2.cr_reason_sk = r.r_reason_sk
) lt ON TRUE
WHERE d_sold.d_year = 1998
  AND p.p_channel_dmail = 'Y'
  AND sm.sm_type = 'AIR'
  AND ws.web_name = 'Internet'
  AND r.r_reason_desc = 'Customer Not Satisfied'
GROUP BY
    s.s_store_name,
    d_sold.d_year,
    p.p_promo_name,
    r.r_reason_desc,
    sm.sm_type,
    wp.wp_url,
    ws.web_name,
    lt.avg_ret_amount
ORDER BY total_net_paid DESC, s.s_store_name
LIMIT 100
