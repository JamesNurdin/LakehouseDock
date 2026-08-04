WITH
sales_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_quantity AS qty,
        ws.ws_ext_sales_price AS amount,
        c.c_customer_id,
        c.c_email_address,
        (
            SELECT SUM(wr.wr_return_amt)
            FROM web_returns wr
            WHERE wr.wr_item_sk = i.i_item_sk
        ) AS metric_val
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(i.i_item_desc, '(?i)Premium')
      AND c.c_email_address LIKE '%@example.com'
),
returns_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_return_quantity AS qty,
        wr.wr_return_amt AS amount,
        c.c_customer_id,
        c.c_email_address,
        (
            SELECT SUM(ws.ws_ext_sales_price)
            FROM web_sales ws
            WHERE ws.ws_item_sk = i.i_item_sk
        ) AS metric_val
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE regexp_like(i.i_item_desc, '(?i)Premium')
      AND c.c_email_address LIKE '%@example.com'
),
union_items AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_item_desc,
        date_sk,
        qty,
        amount,
        c_customer_id,
        c_email_address,
        metric_val
    FROM sales_items
    UNION
    SELECT
        i_item_sk,
        i_item_id,
        i_item_desc,
        date_sk,
        qty,
        amount,
        c_customer_id,
        c_email_address,
        metric_val
    FROM returns_items
),
sales_without_returns AS (
    SELECT i_item_id FROM sales_items
    EXCEPT
    SELECT i_item_id FROM returns_items
),
inventory_warehouses AS (
    SELECT
        inv.inv_item_sk,
        w.w_warehouse_id,
        w.w_city
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
)
SELECT
    ui.i_item_id,
    ui.i_item_desc,
    regexp_extract(ui.i_item_desc, '(Premium|Standard|Basic)', 1) AS tier,
    substring(ui.c_email_address, 1, 5) AS email_prefix,
    ui.amount,
    ui.metric_val AS related_agg,
    iw.w_warehouse_id,
    iw.w_city,
    ui.c_email_address || ' - ' || ui.i_item_id AS email_item_concat
FROM union_items ui
FULL OUTER JOIN inventory_warehouses iw
    ON ui.i_item_sk = iw.inv_item_sk
WHERE ui.amount > 100
ORDER BY ui.amount DESC
LIMIT 100
