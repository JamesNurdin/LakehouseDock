WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        d.d_date,
        cs.cs_catalog_page_sk,
        cs.cs_bill_hdemo_sk
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
)
SELECT
    cp.cp_catalog_page_id,
    s.d_date,
    SUM(s.cs_quantity) AS total_quantity,
    SUM(s.cs_net_paid) AS total_net_paid,
    SUM(s.cs_net_profit) AS total_net_profit,
    COALESCE(SUM(r.cr_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(r.cr_net_loss), 0) AS total_return_loss,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_count
FROM sales s
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
    AND s.cs_item_sk = r.cr_item_sk
JOIN catalog_page cp
    ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN household_demographics hd
    ON s.cs_bill_hdemo_sk = hd.hd_demo_sk
GROUP BY cp.cp_catalog_page_id, s.d_date
ORDER BY total_net_paid DESC
LIMIT 50
