WITH base AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        r.r_reason_desc AS reason_desc,
        d_sold.d_year AS sold_year,
        d_return.d_year AS return_year,
        wp.wp_url,
        inv.inv_quantity_on_hand,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY d_sold.d_date DESC) AS rn_item,
        (
            SELECT AVG(inv2.inv_quantity_on_hand)
            FROM inventory inv2
            WHERE inv2.inv_date_sk = d_sold.d_date_sk
        ) AS avg_inv_qty_on_sold_date
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_item_sk = cr.cr_item_sk
        AND cs.cs_order_number = cr.cr_order_number
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return
        ON cr.cr_returned_time_sk = t_return.t_time_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
        AND inv.inv_item_sk = cs.cs_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_return.d_date_sk
        AND wr.wr_order_number = cs.cs_order_number
    LEFT JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    LEFT JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE EXISTS (
        SELECT 1
        FROM inventory inv_check
        WHERE inv_check.inv_item_sk = cs.cs_item_sk
          AND inv_check.inv_quantity_on_hand > 500
          AND inv_check.inv_date_sk = d_sold.d_date_sk
    )
      AND d_sold.d_year = 2001
)
SELECT
    sold_year,
    reason_desc,
    url_part,
    COUNT(DISTINCT cs_item_sk) AS distinct_items,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cs_net_paid) AS total_net_paid,
    MAX(rn_item) AS max_item_rank,
    AVG(avg_inv_qty_on_sold_date) AS avg_inv_qty_on_date,
    COUNT(*) OVER (PARTITION BY sold_year) AS rows_per_year
FROM base
LEFT JOIN UNNEST(split(wp_url, '/')) AS u(url_part) ON true
GROUP BY ROLLUP(sold_year, reason_desc, url_part)
HAVING SUM(cr_return_amount) > 1000
ORDER BY sold_year DESC, total_return_amount DESC
