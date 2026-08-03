WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_formulation,
        i.i_category,
        i.i_category_id,
        i.i_current_price,
        substring(i.i_formulation, 1, 5) AS form_prefix,
        regexp_extract(i.i_formulation, '(\\d+)', 1) AS digits_part
    FROM item i
    WHERE i.i_formulation LIKE '%plum%'
      AND regexp_like(i.i_formulation, '[a-z]+[0-9]+')
      AND i.i_current_price > (
          SELECT max(i2.i_current_price)
          FROM item i2
          WHERE i2.i_category_id = 6
      )
)
SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    fi.i_category,
    COUNT(DISTINCT sr.sr_ticket_number) AS cnt_returns,
    SUM(sr.sr_return_amt) AS total_return_amt,
    AVG(sr.sr_return_quantity) AS avg_return_qty,
    MAX(fi.form_prefix) AS example_prefix
FROM store_returns sr
JOIN filtered_items fi ON sr.sr_item_sk = fi.i_item_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_item_sk = sr.sr_item_sk
      AND sr2.sr_return_amt > sr.sr_return_amt
)
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, fi.i_category

UNION DISTINCT

SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    fi2.i_category,
    COUNT(DISTINCT sr2.sr_ticket_number) AS cnt_returns,
    SUM(sr2.sr_return_amt) AS total_return_amt,
    AVG(sr2.sr_return_quantity) AS avg_return_qty,
    MAX(fi2.form_prefix) AS example_prefix
FROM store_returns sr2
JOIN (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_formulation,
        i.i_category,
        i.i_category_id,
        i.i_current_price,
        substring(i.i_formulation, 1, 5) AS form_prefix,
        regexp_extract(i.i_formulation, '(\\d+)', 1) AS digits_part
    FROM item i
    WHERE i.i_formulation LIKE '%blue%'
      AND regexp_like(i.i_formulation, '[a-z]+[0-9]+')
) fi2 ON sr2.sr_item_sk = fi2.i_item_sk
JOIN household_demographics hd2 ON sr2.sr_hdemo_sk = hd2.hd_demo_sk
JOIN income_band ib ON hd2.hd_income_band_sk = ib.ib_income_band_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr3
    WHERE sr3.sr_item_sk = sr2.sr_item_sk
      AND sr3.sr_return_amt > sr2.sr_return_amt
)
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, fi2.i_category
ORDER BY total_return_amt DESC
LIMIT 100
