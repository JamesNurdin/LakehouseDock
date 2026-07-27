WITH
    sales_part AS (
        SELECT
            d.d_year,
            i.i_item_id,
            sm.sm_ship_mode_id,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            SUM(cs.cs_net_profit) AS total_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                         AND inv.inv_item_sk = i.i_item_sk
        WHERE cs.cs_quantity > 1
          AND cs.cs_sales_price > 10
          AND d.d_year = 2001
          AND i.i_color IN ('purple', 'pink')
          AND i.i_brand = 'exportischolar #2'
          AND sm.sm_type = 'AIR'
          AND inv.inv_quantity_on_hand > 0
          AND EXISTS (
                SELECT 1
                FROM web_returns wr
                JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
                WHERE wr.wr_item_sk = cs.cs_item_sk
                  AND r.r_reason_desc = 'Damaged'
          )
        GROUP BY d.d_year, i.i_item_id, sm.sm_ship_mode_id
    ),
    returns_part AS (
        SELECT
            d.d_year,
            i.i_item_id,
            NULL AS sm_ship_mode_id,
            -SUM(wr.wr_return_amt) AS total_sales,
            -SUM(wr.wr_net_loss) AS total_profit
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                         AND inv.inv_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
          AND i.i_color = 'purple'
          AND r.r_reason_id = 'AAAAAAAANAAAAAAA'
          AND inv.inv_quantity_on_hand > 0
        GROUP BY d.d_year, i.i_item_id
    ),
    combined AS (
        SELECT * FROM sales_part
        UNION ALL
        SELECT * FROM returns_part
    ),
    agg AS (
        SELECT
            d_year,
            i_item_id,
            sm_ship_mode_id,
            SUM(total_sales) AS sum_sales,
            SUM(total_profit) AS sum_profit,
            COUNT(*) AS cnt_rows
        FROM combined
        GROUP BY d_year, i_item_id, sm_ship_mode_id
    )
SELECT
    d_year,
    i_item_id,
    sm_ship_mode_id,
    sum_sales,
    sum_profit,
    sum_sales / NULLIF(cnt_rows, 0) AS avg_sales_per_row
FROM agg
WHERE sum_sales > 1000
  AND sum_profit < 5000
  AND cnt_rows >= 1
ORDER BY sum_sales DESC
LIMIT 100
