SELECT
    sales_date.d_year,
    sales_date.d_month_seq,
    i.i_category,
    cd.cd_gender,
    SUM(cs.cs_ext_sales_price) AS total_sales_amount,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    SUM(cs.cs_ext_sales_price) - COALESCE(SUM(cr.cr_return_amount), 0) AS net_sales_after_returns,
    CASE WHEN SUM(cs.cs_ext_sales_price) = 0 THEN 0
         ELSE COALESCE(SUM(cr.cr_return_amount), 0) / SUM(cs.cs_ext_sales_price)
    END AS return_rate
FROM
    catalog_sales cs
JOIN
    date_dim sales_date
        ON cs.cs_sold_date_sk = sales_date.d_date_sk
JOIN
    item i
        ON cs.cs_item_sk = i.i_item_sk
JOIN
    customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN
    catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
LEFT JOIN
    date_dim returns_date
        ON cr.cr_returned_date_sk = returns_date.d_date_sk
WHERE
    sales_date.d_date >= DATE '2022-01-01' AND sales_date.d_date < DATE '2023-01-01'
GROUP BY
    sales_date.d_year,
    sales_date.d_month_seq,
    i.i_category,
    cd.cd_gender
ORDER BY
    sales_date.d_year,
    sales_date.d_month_seq,
    i.i_category,
    cd.cd_gender
