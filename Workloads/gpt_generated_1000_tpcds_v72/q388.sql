WITH base AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        w.w_state,
        sr.sr_return_amt,
        sr.sr_refunded_cash,
        sr.sr_reason_sk,
        inv.inv_quantity_on_hand,
        cd.cd_gender,
        hd.hd_vehicle_count,
        sr.sr_return_quantity
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_day = 9
      AND c.c_birth_month = 7
      AND sr.sr_refunded_cash > 1000
      AND sr.sr_reason_sk IN (6, 21)
      AND inv.inv_quantity_on_hand < 500
      AND i.i_current_price BETWEEN 10 AND 100
      AND EXISTS (
          SELECT 1
          FROM inventory inv2
          WHERE inv2.inv_item_sk = i.i_item_sk
            AND inv2.inv_quantity_on_hand > 1000
      )
),
agg AS (
    SELECT
        c_customer_id,
        i_category,
        w_state,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(i_current_price) AS avg_price,
        MAX(sr_refunded_cash) AS max_refunded_cash,
        MIN(sr_return_quantity) AS min_return_qty
    FROM base
    GROUP BY c_customer_id, i_category, w_state
    HAVING SUM(sr_return_amt) > 5000
)
SELECT
    c_customer_id,
    i_category,
    w_state,
    distinct_customers,
    total_return_amt,
    avg_price,
    max_refunded_cash,
    min_return_qty,
    SUM(total_return_amt) OVER (ORDER BY total_return_amt DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return,
    RANK() OVER (ORDER BY total_return_amt DESC) AS return_rank
FROM agg
ORDER BY total_return_amt DESC
LIMIT 100
