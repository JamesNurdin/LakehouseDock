WITH date_info AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq,
           d_date
    FROM date_dim
    WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT *
FROM (
    SELECT
        'Catalog' AS return_source,
        di.d_year,
        di.d_month_seq,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        (SELECT MAX(p.p_cost)
         FROM promotion p
         WHERE p.p_item_sk = i.i_item_sk
           AND p.p_start_date_sk = cr.cr_returned_date_sk) AS max_promo_cost
    FROM catalog_returns cr
    JOIN date_info di ON cr.cr_returned_date_sk = di.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 0
    GROUP BY di.d_year,
             di.d_month_seq,
             i.i_category,
             i.i_item_sk,
             cr.cr_returned_date_sk

    UNION ALL

    SELECT
        'Web' AS return_source,
        di.d_year,
        di.d_month_seq,
        i.i_category,
        SUM(wr.wr_return_amt) AS total_return_amount,
        (SELECT MAX(p.p_cost)
         FROM promotion p
         WHERE p.p_item_sk = i.i_item_sk
           AND p.p_start_date_sk = wr.wr_returned_date_sk) AS max_promo_cost
    FROM web_returns wr
    JOIN date_info di ON wr.wr_returned_date_sk = di.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_return_amt > 0
    GROUP BY di.d_year,
             di.d_month_seq,
             i.i_category,
             i.i_item_sk,
             wr.wr_returned_date_sk
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
