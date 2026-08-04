WITH base AS (
    SELECT
        cc.cc_call_center_id,
        d.d_year,
        inv.inv_quantity_on_hand,
        wr.wr_return_amt
    FROM call_center cc
    FULL OUTER JOIN date_dim d
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001                                  -- filter 1
        AND d.d_month_seq BETWEEN 1 AND 12               -- filter 2
        AND cc.cc_employees > 5000000                    -- filter 3
        AND inv.inv_quantity_on_hand > 800               -- filter 4
        AND wp.wp_type = 'Content'                       -- filter 5
        AND wr.wr_return_amt > 100                       -- filter 6
        AND inv.inv_item_sk IN (
            SELECT wr_item_sk
            FROM web_returns
            WHERE wr_return_quantity > 0
        )
),
agg AS (
    SELECT
        cc_call_center_id,
        d_year,
        COUNT(*) AS txn_count,
        SUM(wr_return_amt) AS sum_return_amt,
        SUM(inv_quantity_on_hand) AS sum_qty_on_hand,
        AVG(wr_return_amt) AS avg_return_amt
    FROM base
    GROUP BY cc_call_center_id, d_year
)
SELECT
    cc_call_center_id,
    d_year,
    txn_count,
    sum_return_amt,
    sum_qty_on_hand,
    avg_return_amt,
    sum_return_amt / NULLIF(sum_qty_on_hand, 0) AS return_per_qty
FROM agg
WHERE txn_count >= 5
ORDER BY sum_return_amt DESC
LIMIT 100
