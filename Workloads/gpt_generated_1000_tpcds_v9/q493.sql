WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        d.d_year,
        i.i_brand,
        i.i_brand_id,
        i.i_item_id,
        i.i_item_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year IN (1999, 2000)
)
SELECT
    combined.d_year,
    combined.i_brand,
    combined.i_item_id,
    combined.total_return_amount,
    combined.avg_return_amount,
    combined.total_net_loss,
    combined.period_label,
    combined.total_quantity_all_time
FROM (
    SELECT
        b.d_year,
        b.i_brand,
        b.i_item_id,
        b.i_item_sk,
        SUM(b.cr_return_amount) AS total_return_amount,
        AVG(b.cr_return_amount) AS avg_return_amount,
        SUM(b.cr_net_loss) AS total_net_loss,
        '1999_Selected_Brands' AS period_label,
        (
            SELECT SUM(cr2.cr_return_quantity)
            FROM catalog_returns cr2
            WHERE cr2.cr_item_sk = b.i_item_sk
        ) AS total_quantity_all_time
    FROM base b
    WHERE b.d_year = 1999 AND b.i_brand_id IN (6008007, 5002002)
    GROUP BY b.d_year, b.i_brand, b.i_item_id, b.i_item_sk
    UNION ALL
    SELECT
        b.d_year,
        b.i_brand,
        b.i_item_id,
        b.i_item_sk,
        SUM(b.cr_return_amount) AS total_return_amount,
        AVG(b.cr_return_amount) AS avg_return_amount,
        SUM(b.cr_net_loss) AS total_net_loss,
        '2000_Other_Brands' AS period_label,
        (
            SELECT SUM(cr2.cr_return_quantity)
            FROM catalog_returns cr2
            WHERE cr2.cr_item_sk = b.i_item_sk
        ) AS total_quantity_all_time
    FROM base b
    WHERE b.d_year = 2000 AND b.i_brand_id IN (2004001, 6016006)
    GROUP BY b.d_year, b.i_brand, b.i_item_id, b.i_item_sk
) AS combined
ORDER BY combined.total_net_loss DESC
LIMIT 100
