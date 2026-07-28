WITH joined AS (
    SELECT
        d.d_date,
        d.d_year,
        c.c_customer_id,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_paid_inc_ship_tax,
        cr.cr_return_amount
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
      AND ws.ws_net_paid_inc_ship_tax > 500
      AND cr.cr_return_amount > 10
      AND c.c_preferred_cust_flag = 'Y'
),
aggregated AS (
    SELECT
        d_date,
        d_year,
        c_customer_id,
        COUNT(DISTINCT ws_order_number) AS orders_cnt,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(cr_return_amount) AS total_returns,
        AVG(ws_net_paid_inc_ship_tax) AS avg_paid_inc_tax,
        MIN(ws_net_paid_inc_ship_tax) AS min_paid_inc_tax,
        MAX(ws_net_paid_inc_ship_tax) AS max_paid_inc_tax
    FROM joined
    GROUP BY d_date, d_year, c_customer_id
)
SELECT
    d_date,
    d_year,
    c_customer_id,
    orders_cnt,
    total_sales,
    total_returns,
    avg_paid_inc_tax,
    min_paid_inc_tax,
    max_paid_inc_tax,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
