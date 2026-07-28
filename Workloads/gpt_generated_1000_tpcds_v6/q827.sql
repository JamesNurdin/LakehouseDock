WITH filtered_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        CONCAT(i.i_item_id, '-', i.i_brand) AS sku_brand,
        regexp_extract(i.i_item_desc, '^(\\w+)', 1) AS first_word,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_return_tax) AS total_return_tax
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
      AND regexp_like(i.i_item_desc, '^.*[A-Z]{3}.*$')
      AND i.i_item_id LIKE 'AA%'
      AND cd.cd_gender LIKE 'M%'
      AND hd.hd_buy_potential LIKE 'HIGH%'
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_brand, i.i_item_desc
)
SELECT
    d_year,
    d_month_seq,
    sku_brand,
    first_word,
    total_return_amount,
    total_return_tax
FROM filtered_returns
ORDER BY total_return_amount DESC
LIMIT 100
