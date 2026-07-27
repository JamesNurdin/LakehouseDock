WITH returns_by_store AS (
    SELECT
        s.s_store_name AS group_name,
        SUM(cr.cr_return_amount) AS total_amount,
        ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_return_amount) DESC) AS rank,
        (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS avg_net_loss_all
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1901
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr3
          WHERE cr3.cr_returned_date_sk = d.d_date_sk
            AND cr3.cr_reversed_charge > 500
      )
    GROUP BY s.s_store_name
    HAVING SUM(cr.cr_return_amount) > 100
),
returns_by_brand AS (
    SELECT
        i.i_brand AS group_name,
        SUM(cr.cr_return_amount) AS total_amount,
        ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_return_amount) DESC) AS rank,
        (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS avg_net_loss_all
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE i.i_category_id = 3
      AND d.d_fy_year = 1901
      AND cr.cr_return_amount > 50
    GROUP BY i.i_brand
    HAVING SUM(cr.cr_return_amount) > 100
)
SELECT
    group_name,
    total_amount,
    rank,
    avg_net_loss_all
FROM (
    SELECT * FROM returns_by_store
    UNION ALL
    SELECT * FROM returns_by_brand
) AS combined
ORDER BY total_amount DESC
LIMIT 100
