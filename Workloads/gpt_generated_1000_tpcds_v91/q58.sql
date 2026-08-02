WITH raw_join AS (
    SELECT
        cu.c_customer_id,
        cu.c_preferred_cust_flag,
        cd.cd_gender,
        d.d_year,
        d.d_month_seq,
        t.t_shift,
        sm.sm_carrier,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        s.s_store_name
    FROM date_dim d
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer cu
        ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_customer_sk = cu.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        d.d_year = 2001
        AND t.t_shift = 'first'
        AND sm.sm_carrier = 'UPS'
        AND cu.c_preferred_cust_flag = 'Y'
        AND cd.cd_gender = 'F'
        AND s.s_store_name IS NOT NULL
),
agg_customer AS (
    SELECT
        c_customer_id,
        d_year,
        SUM(cs_net_paid) AS total_catalog_sales,
        SUM(ws_net_paid) AS total_web_sales,
        SUM(cr_return_amount) AS total_returns,
        SUM(cs_net_profit) + SUM(ws_net_profit) - SUM(cr_return_amount) AS net_profit,
        CASE WHEN SUM(cs_net_profit) + SUM(ws_net_profit) - SUM(cr_return_amount) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag
    FROM raw_join
    WHERE cs_quantity > 0
    GROUP BY c_customer_id, d_year
)
SELECT
    c_customer_id,
    d_year,
    total_catalog_sales,
    total_web_sales,
    total_returns,
    net_profit,
    profit_flag,
    (SELECT AVG(net_profit) FROM agg_customer) AS avg_net_profit
FROM agg_customer
WHERE net_profit > (SELECT AVG(net_profit) FROM agg_customer)
  AND c_customer_id IN (
        SELECT DISTINCT c_customer_id FROM agg_customer WHERE total_catalog_sales > 5000
        INTERSECT
        SELECT DISTINCT c_customer_id FROM agg_customer WHERE total_web_sales > 3000
    )
ORDER BY net_profit DESC
LIMIT 100
