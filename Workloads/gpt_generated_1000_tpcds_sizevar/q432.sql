WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_wholesale_cost,
        cr.cr_return_amount,
        wr.wr_return_amt,
        i.i_category,
        i.i_brand,
        w.w_state,
        r.r_reason_desc,
        array[cs.cs_quantity, cr.cr_return_quantity, wr.wr_return_quantity] AS qty_array,
        cs.cs_wholesale_cost * cs.cs_quantity AS sales_amount
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    JOIN web_returns wr
        ON wr.wr_item_sk = cs.cs_item_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_wholesale_cost > 50
      AND cr.cr_net_loss > 100
      AND hd.hd_vehicle_count >= 0
),
distinct_base AS (
    SELECT DISTINCT * FROM base
),
expanded AS (
    SELECT
        db.i_category,
        db.i_brand,
        db.w_state,
        db.r_reason_desc,
        (db.sales_amount - db.cr_return_amount - db.wr_return_amt) AS net_amount,
        qty
    FROM distinct_base db
    CROSS JOIN UNNEST(db.qty_array) AS t(qty)
)
SELECT
    i_category,
    i_brand,
    w_state,
    r_reason_desc,
    qty,
    SUM(net_amount) AS total_net_amount,
    CASE
        WHEN SUM(net_amount) > 10000 THEN 'HIGH'
        WHEN SUM(net_amount) > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS amount_level,
    RANK() OVER (PARTITION BY i_category ORDER BY SUM(net_amount) DESC) AS category_rank
FROM expanded
GROUP BY ROLLUP (i_category, i_brand, w_state, r_reason_desc, qty)
HAVING SUM(net_amount) > 0
ORDER BY total_net_amount DESC
LIMIT 100
