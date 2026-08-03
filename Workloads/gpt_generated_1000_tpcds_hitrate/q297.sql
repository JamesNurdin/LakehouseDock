WITH base AS (
    SELECT 
        i.i_item_id,
        i.i_item_sk,
        r.r_reason_desc,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_quantity) AS avg_qty,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                       AND inv.inv_item_sk = i.i_item_sk
                       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer cu ON cr.cr_refunded_customer_sk = cu.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE 
        d.d_year = 2001
        AND t.t_hour BETWEEN 8 AND 17
        AND i.i_current_price > 20
        AND w.w_state = 'CA'
        AND hd.hd_buy_potential IN ('501-1000', '>10000')
        AND r.r_reason_desc LIKE '%product%'
    GROUP BY i.i_item_id, i.i_item_sk, r.r_reason_desc, d.d_year
),
year_avg AS (
    SELECT d_year, AVG(total_return_amount) AS avg_total_per_year
    FROM (
        SELECT d.d_year, SUM(cr.cr_return_amount) AS total_return_amount
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year BETWEEN 2000 AND 2002
        GROUP BY d.d_year, cr.cr_returned_date_sk
    ) t
    GROUP BY d_year
),
months AS (
    SELECT d_month_seq
    FROM date_dim
    WHERE d_year = 2001
    GROUP BY d_month_seq
    LIMIT 5
)
SELECT 
    b.i_item_id,
    b.r_reason_desc,
    b.d_year,
    b.total_return_amount,
    b.return_cnt,
    b.avg_qty,
    b.total_on_hand,
    y.avg_total_per_year,
    m.d_month_seq
FROM base b
JOIN year_avg y ON b.d_year = y.d_year
CROSS JOIN months m
WHERE NOT EXISTS (
    SELECT 1 FROM inventory inv2
    WHERE inv2.inv_item_sk = b.i_item_sk
      AND inv2.inv_quantity_on_hand = 0
)
ORDER BY b.total_return_amount DESC
LIMIT 100
