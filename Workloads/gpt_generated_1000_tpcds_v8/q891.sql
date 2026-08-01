WITH
    cr AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_item_sk,
            cr.cr_call_center_sk,
            cr.cr_return_amount,
            cr.cr_return_tax,
            cr.cr_net_loss,
            d.d_year,
            i.i_category,
            i.i_brand,
            i.i_current_price
        FROM
            catalog_returns AS cr
            TABLESAMPLE BERNOULLI (10) /* sample 10% of catalog_returns */
            JOIN date_dim AS d ON cr.cr_returned_date_sk = d.d_date_sk
            JOIN item AS i ON cr.cr_item_sk = i.i_item_sk
            JOIN call_center AS cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        WHERE
            d.d_year BETWEEN 2000 AND 2002
            AND cr.cr_return_amount > 100
            AND cc.cc_state = 'CA'
            AND i.i_current_price IS NOT NULL
            AND cr.cr_return_tax < 50
    ),
    sr_wr AS (
        SELECT
            sr.sr_returned_date_sk,
            sr.sr_item_sk,
            sr.sr_return_amt,
            sr.sr_net_loss,
            wr.wr_returned_date_sk,
            wr.wr_item_sk,
            wr.wr_return_amt,
            wr.wr_net_loss,
            d.d_year,
            i.i_category,
            i.i_brand
        FROM (
            SELECT * FROM store_returns TABLESAMPLE BERNOULLI (5) /* sample 5% */
        ) AS sr
        FULL OUTER JOIN (
            SELECT * FROM web_returns TABLESAMPLE BERNOULLI (5) /* sample 5% */
        ) AS wr
            ON sr.sr_returned_date_sk = wr.wr_returned_date_sk
           AND sr.sr_item_sk = wr.wr_item_sk
        LEFT JOIN date_dim AS d
            ON COALESCE(sr.sr_returned_date_sk, wr.wr_returned_date_sk) = d.d_date_sk
        LEFT JOIN item AS i
            ON COALESCE(sr.sr_item_sk, wr.wr_item_sk) = i.i_item_sk
        WHERE
            d.d_year = 2001
            AND (sr.sr_return_amt > 200 OR wr.wr_return_amt > 200)
    ),
    combined AS (
        SELECT
            cr.d_year AS year,
            cr.i_category AS category,
            cr.i_brand AS brand,
            cr.cr_item_sk,
            cr.cr_returned_date_sk,
            cr.cr_return_amount + COALESCE(sr_wr.sr_return_amt, 0) + COALESCE(sr_wr.wr_return_amt, 0) AS total_return_amount,
            cr.cr_net_loss + COALESCE(sr_wr.sr_net_loss, 0) + COALESCE(sr_wr.wr_net_loss, 0) AS total_net_loss
        FROM cr
        FULL OUTER JOIN sr_wr
            ON cr.cr_item_sk = sr_wr.sr_item_sk
           AND cr.cr_returned_date_sk = sr_wr.sr_returned_date_sk
        WHERE EXISTS (
            SELECT 1
            FROM call_center cc2
            WHERE cc2.cc_call_center_sk = cr.cr_call_center_sk
              AND cc2.cc_gmt_offset > -5
        )
    ),
    aggregated AS (
        SELECT
            year,
            category,
            brand,
            SUM(total_return_amount) AS total_return_amount,
            SUM(total_net_loss) AS total_net_loss
        FROM combined
        GROUP BY CUBE (year, category, brand)
        HAVING SUM(total_return_amount) > 1000
    )
SELECT
    year,
    category,
    brand,
    total_return_amount,
    total_net_loss,
    CASE
        WHEN total_return_amount > 10000 THEN 'High'
        WHEN total_return_amount > 5000  THEN 'Medium'
        ELSE 'Low'
    END AS return_level,
    RANK() OVER (PARTITION BY year ORDER BY total_return_amount DESC) AS return_rank,
    (SELECT MAX(d_year) FROM date_dim) AS max_year
FROM aggregated
ORDER BY year DESC, total_return_amount DESC
LIMIT 100
