WITH base AS (
    SELECT
        cs.cs_order_number,
        cp.cp_department AS cp_department,
        i.i_brand AS i_brand,
        cc.cc_name AS cc_name,
        r.r_reason_desc AS r_reason_desc,
        t.t_hour AS t_hour,
        cs.cs_quantity,
        cs.cs_net_paid,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        c.c_customer_id,
        ca.ca_state,
        wp.wp_url,
        CASE WHEN cs.cs_quantity > 0 THEN 'SALE' ELSE 'RETURN' END AS trans_type
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    WHERE
        cp.cp_department = 'DEPARTMENT'
        AND t.t_hour BETWEEN 8 AND 20
        AND ca.ca_state IN ('CA', 'TX', 'NY')
),
agg AS (
    SELECT
        cp_department,
        i_brand,
        SUM(cs_net_paid) AS total_sales,
        SUM(COALESCE(cr_return_amount, 0) + COALESCE(sr_return_amt, 0) + COALESCE(wr_return_amt, 0)) AS total_returns,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        CASE WHEN SUM(cs_net_paid) > 100000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category
    FROM base
    GROUP BY cp_department, i_brand
),
final AS (
    SELECT
        cp_department,
        i_brand,
        total_sales,
        total_returns,
        distinct_orders,
        sales_category,
        total_sales - total_returns AS net_revenue,
        RANK() OVER (ORDER BY (total_sales - total_returns) DESC) AS revenue_rank,
        (SELECT AVG(total_sales) FROM agg) AS avg_sales_overall
    FROM agg
    WHERE total_sales > 50000
)
SELECT DISTINCT
    cp_department,
    i_brand,
    net_revenue,
    revenue_rank,
    avg_sales_overall,
    sales_category
FROM final
ORDER BY net_revenue DESC
LIMIT 100
