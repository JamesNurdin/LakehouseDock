WITH sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        d_ws.d_date AS sale_date,
        SUM(ws.ws_net_paid) AS sales_amount,
        CAST(0 AS decimal(7,2)) AS returns_amount
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN store s ON s.s_closed_date_sk = d_ws.d_date_sk
    GROUP BY i.i_item_id, i.i_product_name, d_ws.d_date
),
returns_agg AS (
    SELECT
        i_cr.i_item_id AS item_id,
        i_cr.i_product_name AS product_name,
        d_cr.d_date AS sale_date,
        CAST(0 AS decimal(7,2)) AS sales_amount,
        SUM(cr.cr_net_loss) AS returns_amount
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN item i_cr ON cr.cr_item_sk = i_cr.i_item_sk
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s2 ON s2.s_closed_date_sk = d_cr.d_date_sk
    GROUP BY i_cr.i_item_id, i_cr.i_product_name, d_cr.d_date
)
SELECT
    item_id,
    product_name,
    sale_date,
    SUM(sales_amount) AS total_sales,
    SUM(returns_amount) AS total_returns,
    SUM(sales_amount) - SUM(returns_amount) AS net_contribution,
    CASE
        WHEN SUM(sales_amount) - SUM(returns_amount) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS contribution_category
FROM (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
) combined
GROUP BY item_id, product_name, sale_date
ORDER BY net_contribution DESC
LIMIT 100
