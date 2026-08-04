WITH base AS (
    SELECT
        d_sales.d_year,
        w_ship.w_state,
        ws.web_city,
        cd_bill.cd_gender,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer cust_ship
        ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN warehouse w_ship
        ON cs.cs_warehouse_sk = w_ship.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t_return
        ON cr.cr_returned_time_sk = t_return.t_time_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN warehouse w_return
        ON cr.cr_warehouse_sk = w_return.w_warehouse_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sales.d_date_sk
),
agg AS (
    SELECT
        d_year,
        w_state,
        web_city,
        cd_gender,
        SUM(cs_net_paid)               AS total_sales,
        SUM(cs_net_profit)             AS total_profit,
        SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(cr_net_loss, 0))      AS total_return_loss,
        COUNT(DISTINCT cs_order_number)    AS distinct_orders
    FROM base
    WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = base.cs_order_number
          AND cr2.cr_return_amount > 0
    )
    GROUP BY CUBE (d_year, w_state, web_city, cd_gender)
)
SELECT
    d_year,
    w_state,
    web_city,
    cd_gender,
    total_sales,
    total_profit,
    total_return_amount,
    total_return_loss,
    distinct_orders,
    rn
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS rn
    FROM agg
) t
WHERE rn <= 5
ORDER BY d_year, total_sales DESC
