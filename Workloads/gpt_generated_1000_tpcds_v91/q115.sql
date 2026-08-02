WITH
    sales_agg AS (
        SELECT
            d.d_date_sk,
            i.i_item_sk,
            SUM(ss.ss_net_paid) AS total_net_paid
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        GROUP BY d.d_date_sk, i.i_item_sk
        HAVING SUM(ss.ss_net_paid) > 1000
    ),
    returns_agg AS (
        SELECT
            d.d_date_sk,
            i.i_item_sk,
            SUM(cr.cr_return_amount) AS total_return_amount
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        GROUP BY d.d_date_sk, i.i_item_sk
        HAVING SUM(cr.cr_return_amount) > 0
    ),
    common_keys AS (
        SELECT d_date_sk, i_item_sk FROM sales_agg
        INTERSECT
        SELECT d_date_sk, i_item_sk FROM returns_agg
    ),
    full_combined AS (
        SELECT
            COALESCE(s.d_date_sk, r.d_date_sk) AS d_date_sk,
            COALESCE(s.i_item_sk, r.i_item_sk) AS i_item_sk,
            s.total_net_paid,
            r.total_return_amount
        FROM sales_agg s
        FULL OUTER JOIN returns_agg r
            ON s.d_date_sk = r.d_date_sk AND s.i_item_sk = r.i_item_sk
        WHERE s.total_net_paid IS NOT NULL OR r.total_return_amount IS NOT NULL
    )
SELECT
    fc.d_date_sk,
    d.d_date,
    fc.i_item_sk,
    i.i_product_name,
    fc.total_net_paid,
    fc.total_return_amount,
    (fc.total_net_paid - COALESCE(fc.total_return_amount, 0)) AS net_profit,
    RANK() OVER (PARTITION BY fc.i_item_sk ORDER BY (fc.total_net_paid - COALESCE(fc.total_return_amount, 0)) DESC) AS profit_rank,
    r.r_reason_desc,
    b.bucket
FROM full_combined fc
JOIN date_dim d ON fc.d_date_sk = d.d_date_sk
JOIN item i ON fc.i_item_sk = i.i_item_sk
CROSS JOIN (
    SELECT r_reason_desc FROM reason LIMIT 3
) r
CROSS JOIN (
    SELECT 1 AS bucket UNION ALL SELECT 2 AS bucket
) b
WHERE (fc.d_date_sk, fc.i_item_sk) IN (
    SELECT d_date_sk, i_item_sk FROM common_keys
)
ORDER BY d.d_date DESC, net_profit DESC
