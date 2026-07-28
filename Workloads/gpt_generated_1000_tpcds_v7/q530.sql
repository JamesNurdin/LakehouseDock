WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        w.w_state,
        cd_refund.cd_gender,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_reason_sk,
        inv.inv_quantity_on_hand,
        (
            SELECT MAX(inv2.inv_quantity_on_hand)
            FROM inventory inv2
            WHERE inv2.inv_item_sk = i.i_item_sk
              AND inv2.inv_date_sk = d.d_date_sk
        ) AS max_qty_on_hand
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_refund ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN customer_demographics cd_return ON wr.wr_returning_cdemo_sk = cd_return.cd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                     AND inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_am_pm = 'PM'
      AND i.i_brand = 'Brand#45'
      AND w.w_state = 'CA'
      AND cd_refund.cd_gender = 'M'
      AND wr.wr_reason_sk IN (21, 45)
      AND inv.inv_quantity_on_hand > 100
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        w_state,
        cd_gender,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt) AS total_return_amount,
        AVG(wr_return_quantity) AS avg_return_quantity,
        MIN(wr_return_amt) AS min_return_amount,
        MAX(wr_return_amt) AS max_return_amount,
        MAX(max_qty_on_hand) AS max_inventory_qty
    FROM base
    GROUP BY d_year, d_month_seq, i_category, w_state, cd_gender
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    w_state,
    cd_gender,
    return_cnt,
    total_return_amount,
    avg_return_quantity,
    min_return_amount,
    max_return_amount,
    max_inventory_qty,
    SUM(total_return_amount) OVER (PARTITION BY d_year ORDER BY d_month_seq
                                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_year_return
FROM agg
ORDER BY d_year, d_month_seq
