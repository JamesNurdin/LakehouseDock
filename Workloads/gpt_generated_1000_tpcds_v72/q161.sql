WITH returns_data AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_net_loss AS cr_net_loss,
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        cp.cp_catalog_page_number,
        w.w_warehouse_name,
        s.s_store_name,
        p.p_promo_id,
        p.p_purpose
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
        AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
      AND cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 0
      AND i.i_current_price > 0
      AND cp.cp_catalog_page_number IN (3, 6, 8)
      AND (p.p_purpose = 'Discount' OR p.p_promo_id IS NULL)
      AND w.w_city = 'Seattle'
),
promo_returns AS (
    SELECT * FROM returns_data WHERE p_promo_id IS NOT NULL
),
nonpromo_returns AS (
    SELECT * FROM returns_data WHERE p_promo_id IS NULL
),
combined_returns AS (
    SELECT * FROM promo_returns
    UNION ALL
    SELECT * FROM nonpromo_returns
),
aggregated AS (
    SELECT
        i_item_id,
        i_product_name,
        d_year,
        d_month_seq,
        SUM(cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr_net_loss) > 5000 THEN 'High' ELSE 'Medium' END AS loss_category
    FROM combined_returns
    GROUP BY i_item_id, i_product_name, d_year, d_month_seq
    HAVING SUM(cr_net_loss) > 1000
)
SELECT
    i_item_id,
    i_product_name,
    d_year,
    d_month_seq,
    total_net_loss,
    loss_category,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY d_year, loss_rank
LIMIT 100
