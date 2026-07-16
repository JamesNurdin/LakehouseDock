SELECT
    s.s_store_id,
    s.s_city,
    cp.cp_department,
    sd.d_year AS sales_year,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cs.cs_net_profit) AS total_profit,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    SUM(cs.cs_net_paid) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_revenue,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COALESCE(AVG(cr.cr_return_quantity), 0) AS avg_return_quantity,
    MIN(sd.d_date) AS first_sale_date,
    MAX(sd.d_date) AS last_sale_date,
    MIN(rd.d_date) AS first_return_date,
    MAX(rd.d_date) AS last_return_date,
    DATE_DIFF('day', MIN(cp_start.d_date), MIN(cp_end.d_date)) AS page_active_days,
    AVG(date_diff('day', sd.d_date, shd.d_date)) AS avg_shipping_delay,
    SUM(CASE WHEN sd.d_month_seq = 12 THEN cs.cs_net_paid ELSE 0 END) AS december_sales,
    SUM(CASE WHEN rd.d_month_seq = 12 THEN cr.cr_net_loss ELSE 0 END) AS december_return_loss
FROM
    catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim sd
        ON cs.cs_sold_date_sk = sd.d_date_sk
    LEFT JOIN date_dim shd
        ON cs.cs_ship_date_sk = shd.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN date_dim rd
        ON cr.cr_returned_date_sk = rd.d_date_sk
    JOIN store s
        ON true
    JOIN date_dim st
        ON s.s_closed_date_sk = st.d_date_sk
    JOIN date_dim cp_start
        ON cp.cp_start_date_sk = cp_start.d_date_sk
    JOIN date_dim cp_end
        ON cp.cp_end_date_sk = cp_end.d_date_sk
WHERE
    sd.d_year = 2020
    AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_city,
    cp.cp_department,
    sd.d_year
HAVING
    SUM(cs.cs_net_paid) > 0
ORDER BY
    net_revenue DESC
LIMIT 100
