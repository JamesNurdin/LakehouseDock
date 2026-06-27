WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_quantity AS sold_qty,
        cs.cs_ext_sales_price AS sold_amount,
        cs.cs_net_profit AS sold_profit,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
),
joined AS (
    SELECT
        s.cs_order_number,
        s.cs_item_sk,
        s.cs_sold_date_sk,
        s.sold_qty,
        s.sold_amount,
        s.sold_profit,
        s.cs_ship_mode_sk,
        s.cs_warehouse_sk,
        s.cs_catalog_page_sk,
        r.cr_return_quantity,
        r.cr_return_amount,
        r.cr_net_loss,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        p.cp_department,
        p.cp_catalog_number,
        p.cp_catalog_page_number,
        sm.sm_type AS ship_type,
        w.w_warehouse_name
    FROM sales s
    LEFT JOIN returns r
        ON s.cs_order_number = r.cr_order_number
       AND s.cs_item_sk = r.cr_item_sk
    JOIN date_dim d
        ON s.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page p
        ON s.cs_catalog_page_sk = p.cp_catalog_page_sk
    JOIN ship_mode sm
        ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON s.cs_warehouse_sk = w.w_warehouse_sk
)
SELECT
    d_year,
    d_month_seq,
    cp_department,
    cp_catalog_number,
    cp_catalog_page_number,
    ship_type,
    w_warehouse_name,
    SUM(sold_qty) AS total_sold_qty,
    SUM(sold_amount) AS total_sold_amount,
    SUM(sold_profit) AS total_sold_profit,
    SUM(COALESCE(cr_return_quantity, 0)) AS total_return_qty,
    SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(cr_net_loss, 0)) AS total_return_loss,
    CASE WHEN SUM(sold_qty) = 0 THEN 0
         ELSE SUM(COALESCE(cr_return_quantity, 0)) / SUM(sold_qty) END AS return_qty_rate,
    CASE WHEN SUM(sold_amount) = 0 THEN 0
         ELSE SUM(COALESCE(cr_return_amount, 0)) / SUM(sold_amount) END AS return_amount_rate
FROM joined
WHERE d_year = 2001
GROUP BY
    d_year,
    d_month_seq,
    cp_department,
    cp_catalog_number,
    cp_catalog_page_number,
    ship_type,
    w_warehouse_name
ORDER BY total_sold_amount DESC
LIMIT 100
