WITH base AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        dw.d_date,
        dw.d_year,
        dw.d_month_seq,
        rs.r_reason_desc,
        inv.inv_quantity_on_hand,
        wh.w_warehouse_name,
        wh.w_warehouse_sq_ft,
        p.p_promo_name,
        p.p_discount_active,
        p.p_channel_details,
        wr.wr_return_amt,
        wr.wr_refunded_cash,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim dw ON wr.wr_returned_date_sk = dw.d_date_sk
    JOIN reason rs ON wr.wr_reason_sk = rs.r_reason_sk
    JOIN inventory inv ON inv.inv_date_sk = dw.d_date_sk
    JOIN warehouse wh ON inv.inv_warehouse_sk = wh.w_warehouse_sk
    JOIN promotion p ON p.p_start_date_sk <= dw.d_date_sk AND p.p_end_date_sk >= dw.d_date_sk
    WHERE dw.d_year = 2002
      AND dw.d_month_seq BETWEEN 1200 AND 1210
      AND rs.r_reason_desc LIKE '%defect%'
      AND inv.inv_quantity_on_hand > 0
      AND wh.w_warehouse_sq_ft >= 10000
      AND p.p_discount_active = 'Y'
      AND p.p_channel_details LIKE '%churches%'
),
agg AS (
    SELECT
        w_warehouse_name,
        d_year,
        d_month_seq,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS cnt_returns,
        ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY SUM(wr_return_amt) DESC) AS rn
    FROM base
    GROUP BY w_warehouse_name, d_year, d_month_seq
)
SELECT
    a.w_warehouse_name,
    a.d_year,
    a.d_month_seq,
    a.total_return_amt,
    a.total_refunded_cash,
    a.cnt_returns,
    a.rn,
    a.avg_monthly_return_amt
FROM (
    SELECT
        w_warehouse_name,
        d_year,
        d_month_seq,
        total_return_amt,
        total_refunded_cash,
        cnt_returns,
        rn,
        AVG(total_return_amt) OVER (PARTITION BY w_warehouse_name) AS avg_monthly_return_amt
    FROM agg
) a
WHERE a.rn = 1
  AND a.total_return_amt > 1000
  AND a.total_refunded_cash > 500
  AND a.cnt_returns >= 5
  AND a.avg_monthly_return_amt > 1500
  AND NOT EXISTS (
        SELECT 1
        FROM promotion p2
        JOIN date_dim dw2 ON p2.p_start_date_sk <= dw2.d_date_sk AND p2.p_end_date_sk >= dw2.d_date_sk
        WHERE p2.p_promo_name = 'Clearance'
          AND dw2.d_year = a.d_year
          AND dw2.d_month_seq = a.d_month_seq
    )
ORDER BY a.avg_monthly_return_amt DESC
LIMIT 100
