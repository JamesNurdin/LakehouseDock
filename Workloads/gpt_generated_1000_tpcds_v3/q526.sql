SELECT
    cc.cc_name AS call_center_name,
    d.d_year,
    d.d_month_seq,
    CASE WHEN sum(cs.cs_net_profit) >= 0 THEN 'Profit' ELSE 'Loss' END AS overall_profit_status,
    sum(cs.cs_net_paid) AS total_net_paid,
    sum(cs.cs_net_profit) AS total_net_profit,
    avg(cs.cs_list_price) AS avg_list_price,
    sum(cr.cr_return_amount) AS total_return_amount,
    count(DISTINCT cs.cs_order_number) AS distinct_orders,
    sum(CASE WHEN cs.cs_list_price > 100 THEN cs.cs_ext_sales_price ELSE 0 END) AS high_price_sales,
    sum(CASE WHEN cr.cr_return_quantity >= 30 THEN cr.cr_return_amount ELSE 0 END) AS high_quantity_return_amount
FROM
    call_center cc
    JOIN catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND d.d_moy = 3
    AND cc.cc_state = 'CA'
    AND cs.cs_list_price > 100
    AND cs.cs_coupon_amt > 500
    AND cr.cr_return_quantity >= 30
GROUP BY
    cc.cc_name,
    d.d_year,
    d.d_month_seq
ORDER BY
    total_net_paid DESC
LIMIT 100
