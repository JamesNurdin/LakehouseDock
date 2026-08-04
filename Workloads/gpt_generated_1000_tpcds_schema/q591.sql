WITH
    filtered_sales AS (
        SELECT
            ws.ws_sold_date_sk,
            ws.ws_item_sk,
            ws.ws_order_number,
            ws.ws_quantity,
            ws.ws_list_price,
            ws.ws_net_paid_inc_tax,
            ws.ws_bill_customer_sk,
            ws.ws_bill_hdemo_sk,
            d.d_year,
            d.d_month_seq,
            hd.hd_income_band_sk,
            hd.hd_dep_count
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        WHERE d.d_year = 2002
          AND d.d_month_seq BETWEEN 1200 AND 1210
          AND ws.ws_list_price > 50
          AND ws.ws_quantity >= 2
          AND hd.hd_income_band_sk IN (2, 9, 19)
          AND hd.hd_dep_count <= 3
    ),
    returns_filtered AS (
        SELECT
            wr.wr_order_number,
            wr.wr_return_quantity,
            wr.wr_return_amt,
            wr.wr_returned_date_sk,
            d.d_year AS return_year,
            d.d_qoy
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
          AND wr.wr_return_quantity > 0
          AND wr.wr_return_amt > 10
          AND wr.wr_refunded_hdemo_sk IN (
                SELECT hd_demo_sk FROM household_demographics WHERE hd_income_band_sk = 9
          )
    ),
    inventory_filtered AS (
        SELECT
            inv.inv_item_sk,
            inv.inv_warehouse_sk,
            inv.inv_quantity_on_hand,
            d.d_year,
            d.d_week_seq
        FROM inventory inv
        JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
          AND inv.inv_quantity_on_hand > 0
          AND inv.inv_warehouse_sk IN (5, 9, 14)
    ),
    common_items AS (
        SELECT ws_item_sk AS item_sk FROM filtered_sales
        INTERSECT
        SELECT inv_item_sk FROM inventory_filtered
    )
SELECT
    fs.d_year,
    fs.d_month_seq,
    hd.hd_income_band_sk,
    COUNT(DISTINCT fs.ws_bill_customer_sk) AS distinct_customers,
    SUM(DISTINCT fs.ws_quantity) AS distinct_quantity_sum,
    AVG(fs.ws_net_paid_inc_tax) AS avg_net_paid,
    MIN(fs.ws_list_price) AS min_list_price,
    MAX(fs.ws_list_price) AS max_list_price,
    SUM(r.wr_return_amt) AS total_return_amount,
    inv.inv_quantity_on_hand,
    lp.avg_item_price
FROM filtered_sales fs
FULL OUTER JOIN returns_filtered r ON fs.ws_order_number = r.wr_order_number
LEFT JOIN household_demographics hd ON fs.ws_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN inventory_filtered inv ON fs.ws_item_sk = inv.inv_item_sk
LEFT JOIN LATERAL (
    SELECT avg(ws2.ws_list_price) AS avg_item_price
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = fs.ws_item_sk
) lp ON TRUE
WHERE fs.ws_item_sk IN (SELECT item_sk FROM common_items)
GROUP BY
    fs.d_year,
    fs.d_month_seq,
    hd.hd_income_band_sk,
    inv.inv_quantity_on_hand,
    lp.avg_item_price
ORDER BY
    fs.d_year DESC,
    fs.d_month_seq ASC,
    distinct_customers DESC
LIMIT 100
