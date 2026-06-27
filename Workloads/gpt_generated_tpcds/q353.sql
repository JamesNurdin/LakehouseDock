WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cc.cc_name,
        sd.d_date,
        month(sd.d_date) AS sold_month,
        year(sd.d_date) AS sold_year,
        st.t_hour AS sold_hour
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim sd ON cs.cs_sold_date_sk = sd.d_date_sk
    JOIN time_dim st ON cs.cs_sold_time_sk = st.t_time_sk
    WHERE st.t_hour BETWEEN 9 AND 17
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        rd.d_date AS return_date,
        month(rd.d_date) AS return_month,
        year(rd.d_date) AS return_year,
        rt.t_hour AS return_hour
    FROM catalog_returns cr
    JOIN date_dim rd ON cr.cr_returned_date_sk = rd.d_date_sk
    JOIN time_dim rt ON cr.cr_returned_time_sk = rt.t_time_sk
    WHERE rt.t_hour BETWEEN 9 AND 17
)
SELECT
    sales.cc_name,
    sales.sold_year,
    sales.sold_month,
    sum(sales.cs_ext_sales_price) AS total_ext_sales_price,
    sum(sales.cs_net_paid) AS total_net_paid,
    sum(sales.cs_net_profit) AS total_net_profit,
    sum(coalesce(returns.cr_return_amount, 0)) AS total_return_amount,
    sum(coalesce(returns.cr_return_tax, 0)) AS total_return_tax,
    sum(coalesce(returns.cr_net_loss, 0)) AS total_return_net_loss
FROM sales
LEFT JOIN returns
    ON sales.cs_order_number = returns.cr_order_number
    AND sales.cs_item_sk = returns.cr_item_sk
    AND sales.cs_call_center_sk = returns.cr_call_center_sk
    AND sales.cs_catalog_page_sk = returns.cr_catalog_page_sk
WHERE sales.sold_year = 2001
GROUP BY sales.cc_name, sales.sold_year, sales.sold_month
ORDER BY sales.cc_name, sales.sold_year, sales.sold_month
