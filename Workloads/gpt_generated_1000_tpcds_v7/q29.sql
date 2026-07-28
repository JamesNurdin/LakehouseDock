WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        i.i_category_id,
        i.i_class_id,
        d.d_year,
        sm.sm_type,
        inv.inv_quantity_on_hand,
        cr.cr_return_amount,
        r.r_reason_desc,
        wr.wr_return_amt,
        ws.web_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND i.i_category_id IN (5, 7)
      AND sm.sm_type = 'AIR'
      AND inv.inv_quantity_on_hand > 0
      AND (cr.cr_return_amount IS NOT NULL OR wr.wr_return_amt IS NOT NULL)
)
SELECT
    sa.d_year,
    sa.i_category_id,
    COUNT(DISTINCT sa.cs_order_number) AS orders,
    SUM(sa.cs_net_paid) AS total_net_paid,
    AVG(sa.cs_net_profit) AS avg_net_profit,
    SUM(COALESCE(sa.cr_return_amount, 0) + COALESCE(sa.wr_return_amt, 0)) AS total_returns_amount,
    MAX(sa.inv_quantity_on_hand) AS max_inventory_on_hand,
    (
        SELECT COUNT(*)
        FROM reason r2
        WHERE r2.r_reason_desc LIKE '%defect%'
    ) AS defect_reason_count
FROM sales_agg sa
GROUP BY sa.d_year, sa.i_category_id
HAVING SUM(sa.cs_net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
