WITH
    inv_sample AS (
        SELECT *
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
        WHERE inv_quantity_on_hand > 600
    ),
    inv_agg AS (
        SELECT
            inv_warehouse_sk,
            inv_date_sk,
            array_agg(inv_quantity_on_hand) AS quantities_array,
            sum(inv_quantity_on_hand) AS total_qty
        FROM inv_sample
        GROUP BY inv_warehouse_sk, inv_date_sk
    ),
    wh_agg AS (
        SELECT
            w.w_warehouse_sk,
            w.w_warehouse_id,
            w.w_warehouse_name,
            w.w_city,
            w.w_country,
            i.total_qty,
            i.quantities_array,
            i.inv_date_sk
        FROM warehouse w
        JOIN inv_agg i
            ON w.w_warehouse_sk = i.inv_warehouse_sk
    ),
    positive_orders AS (
        SELECT wr_order_number
        FROM web_returns
        WHERE wr_net_loss > 0
    ),
    nonpositive_orders AS (
        SELECT wr_order_number
        FROM web_returns
        WHERE wr_net_loss <= 0
    ),
    diff_orders AS (
        SELECT po.wr_order_number
        FROM positive_orders po
        EXCEPT
        SELECT npo.wr_order_number
        FROM nonpositive_orders npo
    ),
    base AS (
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_returning_customer_sk,
            wr.wr_order_number,
            wr.wr_return_amt,
            wr.wr_net_loss,
            c.c_first_name,
            c.c_last_name,
            d.d_year,
            d.d_month_seq,
            cc.cc_state,
            cp.cp_department,
            wh.w_warehouse_name,
            wh.total_qty,
            wh.quantities_array,
            wh.w_country,
            wh.inv_date_sk
        FROM web_returns wr
        JOIN diff_orders dof
            ON wr.wr_order_number = dof.wr_order_number
        JOIN date_dim d
            ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN customer c
            ON wr.wr_returning_customer_sk = c.c_customer_sk
        JOIN call_center cc
            ON cc.cc_closed_date_sk = d.d_date_sk
        JOIN catalog_page cp
            ON cp.cp_start_date_sk = d.d_date_sk
        JOIN wh_agg wh
            ON wh.inv_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND cc.cc_state = 'CA'
          AND wh.w_country = 'United States'
    )
SELECT
    b.wr_order_number,
    b.c_first_name,
    b.c_last_name,
    b.wr_return_amt,
    b.wr_net_loss,
    b.d_year,
    b.cc_state,
    b.cp_department,
    b.w_warehouse_name,
    b.total_qty,
    q.quantity,
    ROW_NUMBER() OVER (PARTITION BY b.wr_returning_customer_sk ORDER BY b.wr_returned_date_sk DESC) AS rn,
    CASE WHEN b.wr_net_loss > 100 THEN 'High Loss' ELSE 'Low/Medium Loss' END AS loss_category,
    (
        SELECT sum(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_returning_customer_sk = b.wr_returning_customer_sk
    ) AS total_return_amt_for_customer
FROM base b
CROSS JOIN UNNEST(b.quantities_array) AS q(quantity)
WHERE q.quantity > 650
ORDER BY b.wr_net_loss DESC, rn
LIMIT 100
