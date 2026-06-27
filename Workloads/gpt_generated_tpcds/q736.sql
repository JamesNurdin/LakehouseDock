WITH sales_agg AS (
    SELECT
        ds.d_year AS year,
        ds.d_moy AS month,
        i.i_item_id AS item_id,
        i.i_category AS category,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY ds.d_year, ds.d_moy, i.i_item_id, i.i_category
),
returns_agg AS (
    SELECT
        dr.d_year AS year,
        dr.d_moy AS month,
        i.i_item_id AS item_id,
        i.i_category AS category,
        SUM(wr.wr_return_quantity) AS total_quantity_returned,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY dr.d_year, dr.d_moy, i.i_item_id, i.i_category
)
SELECT
    sa.year,
    sa.month,
    sa.item_id,
    sa.category,
    sa.total_quantity_sold,
    COALESCE(ra.total_quantity_returned, 0) AS total_quantity_returned,
    sa.total_sales_amount,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    sa.total_net_profit,
    (COALESCE(ra.total_quantity_returned, 0) * 1.0) / NULLIF(sa.total_quantity_sold, 0) AS return_rate,
    sa.total_discount / NULLIF(sa.total_quantity_sold, 0) AS avg_discount_per_qty
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.year = ra.year
   AND sa.month = ra.month
   AND sa.item_id = ra.item_id
   AND sa.category = ra.category
ORDER BY sa.year, sa.month, sa.total_sales_amount DESC
