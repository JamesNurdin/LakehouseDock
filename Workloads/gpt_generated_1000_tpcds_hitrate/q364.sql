WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_product_name,
        i_formulation,
        i_units,
        regexp_extract(i_formulation, '(\\d+)', 1) AS formulation_num,
        CASE
            WHEN regexp_like(i_formulation, '^\\d{9}.*blue') THEN 'BluePattern'
            ELSE 'OtherPattern'
        END AS formulation_category
    FROM item
    WHERE i_units LIKE '%on%'
      AND regexp_like(i_formulation, 'blue')
),
agg_returns AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        f.formulation_category,
        f.formulation_num,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_net_loss) DESC) AS rn_year
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN filtered_items f
        ON cr.cr_item_sk = f.i_item_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
      AND ib.ib_upper_bound >= 50000
      AND (hd.hd_vehicle_count > 2 OR hd.hd_buy_potential LIKE '%5000%')
      AND EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_item_sk = cr.cr_item_sk
              AND wr.wr_returned_date_sk = cr.cr_returned_date_sk
              AND wr.wr_return_amt > 100
        )
    GROUP BY d.d_year, d.d_quarter_seq, f.formulation_category, f.formulation_num
    HAVING SUM(cr.cr_net_loss) > 0
)
SELECT
    a.d_year,
    a.d_quarter_seq,
    a.formulation_category,
    a.formulation_num,
    CONCAT(a.formulation_category, '_Q', CAST(a.d_quarter_seq AS VARCHAR)) AS cat_quarter,
    a.total_net_loss,
    a.return_cnt,
    (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS avg_net_loss_all,
    a.rn_year
FROM agg_returns a
ORDER BY a.d_year ASC, a.d_quarter_seq DESC, a.total_net_loss DESC
LIMIT 100
