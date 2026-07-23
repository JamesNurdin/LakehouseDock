WITH inventory_summary AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    inv_sum.total_quantity_on_hand,
    d_store.d_date AS store_return_date,
    t_store.t_hour AS store_return_hour,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    cr.cr_return_amount,
    wr.wr_return_amt,
    CASE
        WHEN cr.cr_return_amount > 500 THEN 'High'
        WHEN cr.cr_return_amount > 200 THEN 'Medium'
        ELSE 'Low'
    END AS catalog_return_severity,
    (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS avg_promo_cost,
    RANK() OVER (
        PARTITION BY i.i_item_id
        ORDER BY (COALESCE(sr.sr_return_amt, 0) + COALESCE(cr.cr_return_amount, 0) + COALESCE(wr.wr_return_amt, 0)) DESC
    ) AS return_amount_rank,
    CASE WHEN EXISTS (
        SELECT 1
        FROM promotion p3
        JOIN date_dim d_ps ON p3.p_start_date_sk = d_ps.d_date_sk
        JOIN date_dim d_pe ON p3.p_end_date_sk = d_pe.d_date_sk
        WHERE p3.p_item_sk = i.i_item_sk
          AND p3.p_discount_active = 'Y'
          AND d_ps.d_date <= DATE '2001-12-31'
          AND d_pe.d_date >= DATE '2001-01-01'
    ) THEN 'Yes' ELSE 'No' END AS has_active_promotion
FROM
    inventory_summary inv_sum
    JOIN item i ON inv_sum.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv_sum.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_store ON sr.sr_returned_date_sk = d_store.d_date_sk
    LEFT JOIN time_dim t_store ON sr.sr_return_time_sk = t_store.t_time_sk
    LEFT JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d_catalog ON cr.cr_returned_date_sk = d_catalog.d_date_sk
    LEFT JOIN time_dim t_catalog ON cr.cr_returned_time_sk = t_catalog.t_time_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_web ON wr.wr_returned_date_sk = d_web.d_date_sk
    LEFT JOIN time_dim t_web ON wr.wr_returned_time_sk = t_web.t_time_sk
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE
    d_store.d_year = 2001
    AND i.i_category = 'Electronics'
    AND c.c_birth_year BETWEEN 1950 AND 1970
    AND t_store.t_hour BETWEEN 8 AND 12
    AND d_store.d_date >= DATE '2001-01-01'
ORDER BY
    return_amount_rank,
    i.i_item_id
LIMIT 100
