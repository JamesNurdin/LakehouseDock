WITH
    store_ret AS (
        SELECT
            c.c_customer_id,
            SUM(sr.sr_return_amt_inc_tax) AS total_store_return,
            COUNT(*) AS store_ret_cnt,
            MIN(d.d_date) AS first_store_ret_date
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        WHERE d.d_year = 2001
          AND sr.sr_fee > 20
          AND sr.sr_return_amt_inc_tax < 2000
        GROUP BY c.c_customer_id
    ),
    web_ret AS (
        SELECT
            c.c_customer_id,
            SUM(wr.wr_return_amt_inc_tax) AS total_web_return,
            COUNT(*) AS web_ret_cnt,
            MIN(d.d_date) AS first_web_ret_date
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        WHERE d.d_year = 2001
          AND wr.wr_fee > 15
          AND wr.wr_return_amt_inc_tax < 1500
        GROUP BY c.c_customer_id
    ),
    intersect_customers AS (
        SELECT c_customer_id FROM store_ret
        INTERSECT
        SELECT c_customer_id FROM web_ret
    ),
    inventory_agg AS (
        SELECT
            i.inv_warehouse_sk,
            w.w_warehouse_name,
            COUNT(DISTINCT ic.c_customer_id) AS unique_customers,
            SUM(i.inv_quantity_on_hand) AS total_qty,
            CASE
                WHEN SUM(i.inv_quantity_on_hand) > 10000 THEN 'High'
                WHEN SUM(i.inv_quantity_on_hand) > 5000  THEN 'Medium'
                ELSE 'Low'
            END AS qty_bucket
        FROM intersect_customers ic
        JOIN customer c ON c.c_customer_id = ic.c_customer_id
        JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
        JOIN inventory i ON i.inv_date_sk = d_ship.d_date_sk
        JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
        GROUP BY i.inv_warehouse_sk, w.w_warehouse_name
    ),
    lateral_site AS (
        SELECT
            ia.inv_warehouse_sk,
            ia.w_warehouse_name,
            ia.qty_bucket,
            ia.total_qty,
            ia.unique_customers,
            ws.web_site_id,
            ws.web_tax_percentage,
            ws.web_rec_start_date,
            ws.web_rec_end_date
        FROM inventory_agg ia
        LEFT JOIN LATERAL (
            SELECT ws.web_site_id,
                   ws.web_tax_percentage,
                   ws.web_rec_start_date,
                   ws.web_rec_end_date
            FROM web_site ws
            JOIN date_dim d_open  ON ws.web_open_date_sk  = d_open.d_date_sk
            JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
            WHERE d_open.d_year = 2001
              AND d_close.d_year = 2002
              AND ws.web_tax_percentage > 0.05
            LIMIT 1
        ) ws ON TRUE
    )
SELECT
    ls.w_warehouse_name,
    ls.qty_bucket,
    ls.total_qty,
    ls.unique_customers,
    ls.web_site_id,
    ls.web_tax_percentage
FROM lateral_site ls
WHERE ls.total_qty > 0
ORDER BY ls.total_qty DESC, ls.w_warehouse_name
LIMIT 100
