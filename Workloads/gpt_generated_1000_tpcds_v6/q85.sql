WITH combined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_ext_sales_price
    FROM catalog_sales cs
    LEFT JOIN web_sales ws
        ON cs.cs_sold_time_sk = ws.ws_sold_time_sk
       AND cs.cs_item_sk = ws.ws_item_sk
       AND cs.cs_bill_customer_sk = ws.ws_bill_customer_sk
),
joined AS (
    SELECT
        t.t_hour,
        i.i_category,
        cd.cd_education_status,
        cc.cc_name,
        COALESCE(comb.cs_quantity, 0) + COALESCE(comb.ws_quantity, 0) AS total_quantity,
        COALESCE(comb.cs_net_paid, 0) + COALESCE(comb.ws_net_paid, 0) AS total_net_paid,
        COALESCE(comb.cs_ext_sales_price, 0) + COALESCE(comb.ws_ext_sales_price, 0) AS total_ext_sales_price,
        comb.cs_order_number
    FROM combined comb
    JOIN time_dim t
        ON comb.cs_sold_time_sk = t.t_time_sk
    JOIN item i
        ON comb.cs_item_sk = i.i_item_sk
    JOIN call_center cc
        ON comb.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
        ON comb.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE
        t.t_hour BETWEEN 8 AND 17
        AND i.i_category = 'Sports'
        AND cd.cd_education_status = 'Advanced Degree'
        AND cc.cc_state = 'CA'
),
agg AS (
    SELECT
        t_hour,
        i_category,
        cd_education_status,
        cc_name,
        SUM(total_quantity) AS sum_quantity,
        SUM(total_ext_sales_price) AS sum_sales,
        AVG(total_ext_sales_price) AS avg_sales,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        CASE
            WHEN SUM(total_ext_sales_price) > 100000 THEN 'HIGH'
            ELSE 'NORMAL'
        END AS sales_volume_category
    FROM joined
    GROUP BY
        t_hour,
        i_category,
        cd_education_status,
        cc_name
)
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY sum_sales DESC) AS category_rank
FROM agg
ORDER BY sum_sales DESC
LIMIT 100
