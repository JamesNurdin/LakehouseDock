WITH return_stats AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        i.i_category,
        i.i_item_id,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_store_credit) AS avg_store_credit
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2020
      AND cr.cr_return_amount > 100
      AND cr.cr_store_credit < 300
      AND ca.ca_location_type = 'apartment'
      AND cd.cd_gender = 'M'
    GROUP BY cr.cr_item_sk, cr.cr_returned_date_sk, i.i_category, i.i_item_id, d.d_year
)
SELECT
    rs.i_category,
    rs.d_year,
    rs.total_return_amount,
    rs.return_cnt,
    rs.avg_store_credit,
    inv.inv_quantity_on_hand,
    p.p_promo_name,
    COUNT(DISTINCT rs.i_item_id) AS distinct_items
FROM return_stats rs
JOIN inventory inv ON inv.inv_item_sk = rs.cr_item_sk AND inv.inv_date_sk = rs.cr_returned_date_sk
JOIN promotion p ON p.p_item_sk = rs.cr_item_sk
                AND p.p_start_date_sk <= rs.cr_returned_date_sk
                AND p.p_end_date_sk >= rs.cr_returned_date_sk
WHERE EXISTS (
    SELECT 1 FROM web_page wp
    WHERE wp.wp_creation_date_sk = rs.cr_returned_date_sk
)
GROUP BY rs.i_category, rs.d_year, rs.total_return_amount, rs.return_cnt, rs.avg_store_credit, inv.inv_quantity_on_hand, p.p_promo_name
HAVING SUM(rs.total_return_amount) > 5000
ORDER BY rs.total_return_amount DESC
LIMIT 100
