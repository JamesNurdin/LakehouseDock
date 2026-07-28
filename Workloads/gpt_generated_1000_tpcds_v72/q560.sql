WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        i.i_category,
        d_sold.d_year AS sold_year,
        sm.sm_type AS ship_type,
        cc.cc_name,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        MIN(cs.cs_sales_price) AS min_sales_price,
        MAX(cs.cs_list_price) AS max_list_price,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        c.c_birth_country IN ('MOZAMBIQUE', 'VANUATU')
        AND c.c_first_name = 'William'
        AND d_sold.d_year = 2002
        AND i.i_brand = 'Brand#23'
        AND sm.sm_type = 'AIR'
        AND cc.cc_state = 'CA'
        AND cp.cp_department = 'Sports'
        AND wp.wp_image_count > 3
    GROUP BY
        c.c_customer_id,
        i.i_category,
        d_sold.d_year,
        sm.sm_type,
        cc.cc_name
)
SELECT
    *,
    RANK() OVER (ORDER BY total_net_paid DESC) AS net_paid_rank,
    SUM(total_net_paid) OVER (ORDER BY total_net_paid DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
