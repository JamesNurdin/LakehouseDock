WITH joined AS (
    SELECT
        i.i_category,
        d.d_year,
        c.c_customer_id,
        hd.hd_income_band_sk,
        inv.inv_quantity_on_hand,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        CASE WHEN wr.wr_return_quantity > 10 THEN 'Large' ELSE 'Small' END AS qty_bucket
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
      AND wr.wr_return_quantity BETWEEN 2 AND 50
      AND wr.wr_return_amt > 5.0
      AND i.i_current_price BETWEEN 20 AND 500
      AND hd.hd_vehicle_count >= 1
      AND c.c_preferred_cust_flag = 'Y'
      AND (inv.inv_quantity_on_hand IS NULL OR inv.inv_quantity_on_hand >= wr.wr_return_quantity)
),
agg AS (
    SELECT
        i_category,
        d_year,
        SUM(wr_return_quantity) AS sum_qty,
        SUM(wr_net_loss) AS sum_loss,
        CASE WHEN SUM(wr_return_quantity) > 200 THEN 'High' ELSE 'Low' END AS volume_flag
    FROM joined
    GROUP BY GROUPING SETS (
        (i_category, d_year),
        (i_category),
        (d_year),
        ()
    )
)
SELECT
    COALESCE(i_category, 'All Categories') AS category,
    d_year,
    sum_qty,
    sum_loss,
    volume_flag,
    AVG(sum_loss) OVER (PARTITION BY i_category) AS avg_loss_per_category
FROM agg a
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    JOIN customer c2
        ON wr2.wr_returning_customer_sk = c2.c_customer_sk
    JOIN item i2
        ON wr2.wr_item_sk = i2.i_item_sk
    WHERE i2.i_category = a.i_category
      AND c2.c_preferred_cust_flag = 'N'
)
ORDER BY category ASC, d_year DESC
