WITH monthly_ret AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(*) AS return_cnt,
        COALESCE(SUM(p.p_cost), 0) AS total_promo_cost,
        AVG(i.inv_quantity_on_hand) AS avg_inventory_qty
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN promotion p
        ON sr.sr_item_sk = p.p_item_sk
        AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    LEFT JOIN inventory i
        ON i.inv_item_sk = sr.sr_item_sk
        AND i.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, r.r_reason_desc
)
SELECT
    d_year,
    d_month_seq,
    r_reason_desc,
    total_return_amt,
    return_cnt,
    total_promo_cost,
    avg_inventory_qty
FROM monthly_ret
ORDER BY total_return_amt DESC
LIMIT 100
