WITH sales_agg AS (
    SELECT
        i.i_category AS category,
        td.t_hour AS hour,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE
        td.t_time_id IN ('AAAAAAAAABAAAAAA', 'AAAAAAAACAAAAAAA', 'AAAAAAAAPAAAAAAA')
        AND td.t_second BETWEEN 0 AND 15
        AND ca_bill.ca_gmt_offset = -5.00
        AND ca_ship.ca_street_type = 'ST             '
        AND cs.cs_ext_wholesale_cost > 1000.00
    GROUP BY i.i_category, td.t_hour
)
SELECT
    sa.category,
    sa.hour,
    sa.total_sales,
    sa.total_discount,
    sa.order_cnt,
    sa.total_sales / NULLIF(sa.order_cnt, 0) AS avg_sales_per_order,
    (
        SELECT COUNT(*)
        FROM sales_agg sa2
        WHERE sa2.total_sales > sa.total_sales
    ) AS higher_sales_category_count
FROM sales_agg sa
WHERE sa.total_sales > (
    SELECT AVG(total_sales) FROM sales_agg
)
ORDER BY sa.total_sales DESC
LIMIT 100
