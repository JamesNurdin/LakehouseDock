WITH base AS (
    SELECT
        d.d_year,
        i.i_category,
        cd.cd_credit_rating,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number,
        w.w_warehouse_sq_ft
    FROM call_center cc
    JOIN catalog_returns cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
       AND ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND cd.cd_credit_rating = 'Good'
)
SELECT
    d_year,
    i_category,
    cd_credit_rating,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_net_loss) AS avg_net_loss,
    COUNT(DISTINCT cr_order_number) AS distinct_orders,
    MAX(w_warehouse_sq_ft) AS max_warehouse_size,
    SUM(SUM(cr_return_amount)) OVER (PARTITION BY i_category ORDER BY d_year) AS cumulative_return_by_category
FROM base
GROUP BY d_year, i_category, cd_credit_rating
ORDER BY total_return_amount DESC
LIMIT 100
