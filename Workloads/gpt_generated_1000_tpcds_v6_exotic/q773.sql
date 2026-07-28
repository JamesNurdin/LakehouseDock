WITH
    income_band_desc AS (
        SELECT
            ib_income_band_sk,
            concat(CAST(ib_lower_bound AS varchar), '-', CAST(ib_upper_bound AS varchar)) AS band_range
        FROM income_band
    ),
    catalog_part AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            ibd.band_range,
            cr.cr_net_loss AS loss,
            'catalog' AS source
        FROM catalog_returns cr
        JOIN catalog_sales cs
            ON cr.cr_order_number = cs.cs_order_number
           AND cr.cr_item_sk = cs.cs_item_sk
        JOIN date_dim d
            ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN household_demographics hd
            ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band_desc ibd
            ON hd.hd_income_band_sk = ibd.ib_income_band_sk
        WHERE EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_promo_sk = cs.cs_promo_sk
              AND p.p_cost > 100
        )
    ),
    web_part AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            ibd.band_range,
            wr.wr_net_loss AS loss,
            'web' AS source
        FROM web_returns wr
        JOIN date_dim d
            ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN household_demographics hd
            ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band_desc ibd
            ON hd.hd_income_band_sk = ibd.ib_income_band_sk
        WHERE (SELECT avg(wp_char_count)
               FROM web_page wp
               WHERE wp.wp_web_page_sk = wr.wr_web_page_sk) > 1200
    )
SELECT
    d_year,
    d_month_seq,
    band_range,
    source,
    SUM(loss) AS total_loss
FROM (
    SELECT * FROM catalog_part
    UNION ALL
    SELECT * FROM web_part
) AS combined
GROUP BY GROUPING SETS (
    (d_year, d_month_seq, band_range, source),
    (d_year, band_range, source),
    (d_year, source),
    (source),
    ()
)
ORDER BY d_year DESC, d_month_seq, band_range
LIMIT 100
