WITH sales_agg AS (
    SELECT
        cs_item_sk,
        cs_sold_date_sk,
        cs_call_center_sk,
        cs_bill_customer_sk,
        cs_bill_addr_sk,
        cs_bill_hdemo_sk,
        cs_order_number,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_net_paid
    FROM catalog_sales
    GROUP BY
        cs_item_sk,
        cs_sold_date_sk,
        cs_call_center_sk,
        cs_bill_customer_sk,
        cs_bill_addr_sk,
        cs_bill_hdemo_sk,
        cs_order_number
),
orders_without_returns AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
)
SELECT
    d_sold.d_year,
    i.i_category,
    SUM(sa.total_net_paid) AS sum_net_paid,
    SUM(sa.total_quantity) AS sum_quantity,
    COUNT(DISTINCT sa.cs_order_number) AS distinct_orders,
    CASE WHEN d_sold.d_year = 2001 THEN 'Y2001' ELSE 'OtherYear' END AS year_group,
    SUM(metric_val) AS sum_metric
FROM sales_agg sa
JOIN item i
    ON sa.cs_item_sk = i.i_item_sk
JOIN date_dim d_sold
    ON sa.cs_sold_date_sk = d_sold.d_date_sk
JOIN call_center cc_sales
    ON sa.cs_call_center_sk = cc_sales.cc_call_center_sk
CROSS JOIN UNNEST(ARRAY[cc_sales.cc_gmt_offset, cc_sales.cc_tax_percentage]) AS u(metric_val)
JOIN promotion p
    ON i.i_item_sk = p.p_item_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = sa.cs_order_number
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN call_center cc_return
    ON cr.cr_call_center_sk = cc_return.cc_call_center_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d_return.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sold.d_date_sk
JOIN customer c
    ON sa.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON sa.cs_bill_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN orders_without_returns orw
    ON sa.cs_order_number = orw.cs_order_number
GROUP BY GROUPING SETS (
    (d_sold.d_year, i.i_category),
    (i.i_category),
    ()
)
LIMIT 100
