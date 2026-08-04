WITH
    aggregated_returns AS (
        SELECT
            i.i_item_sk AS i_item_sk,
            i.i_category AS i_category,
            d.d_year AS d_year,
            SUM(cr.cr_return_quantity) AS total_return_quantity,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_count
        FROM catalog_returns cr
        JOIN date_dim d
          ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i
          ON cr.cr_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk, i.i_category, d.d_year
    ),
    high_cost_items AS (
        SELECT i_item_sk FROM item WHERE i_wholesale_cost > 5.00
    ),
    recent_end_items AS (
        SELECT i_item_sk FROM item WHERE i_rec_end_date >= DATE '2000-01-01'
    ),
    intersect_items AS (
        SELECT i_item_sk FROM high_cost_items
        INTERSECT
        SELECT i_item_sk FROM recent_end_items
    ),
    except_items AS (
        SELECT i_item_sk FROM item WHERE i_container = 'Unknown'
        EXCEPT
        SELECT i_item_sk FROM item WHERE i_rec_end_date < DATE '1999-01-01'
    ),
    customer_filtered AS (
        SELECT
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            c.c_birth_year,
            c.c_current_cdemo_sk,
            c.c_current_hdemo_sk
        FROM customer c
        WHERE c.c_customer_sk IN (
            SELECT cr_refunded_customer_sk
            FROM catalog_returns
            WHERE cr_return_quantity > 1
        )
    ),
    demographics AS (
        SELECT
            cf.c_customer_sk,
            cd.cd_gender,
            cd.cd_marital_status,
            hd.hd_demo_sk,
            hd.hd_buy_potential,
            ib.ib_lower_bound,
            ib.ib_upper_bound
        FROM customer_filtered cf
        JOIN customer_demographics cd
          ON cf.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
          ON cf.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
          ON hd.hd_income_band_sk = ib.ib_income_band_sk
    ),
    full_item_return AS (
        SELECT
            COALESCE(i.i_item_sk, cr.cr_item_sk) AS item_sk,
            i.i_category AS i_category,
            cr.cr_return_amount,
            cr.cr_return_quantity
        FROM item i
        FULL OUTER JOIN catalog_returns cr
          ON i.i_item_sk = cr.cr_item_sk
    )
SELECT
    ar.i_category,
    SUM(ar.total_return_amount) AS sum_return_amount,
    AVG(ar.total_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT ar.d_year) AS years_covered,
    AVG(demo.ib_lower_bound) AS avg_income_lower_bound
FROM aggregated_returns ar
JOIN intersect_items ii
  ON ar.i_item_sk = ii.i_item_sk
JOIN except_items ei
  ON ar.i_item_sk = ei.i_item_sk
JOIN demographics demo
  ON 1 = 1
LEFT JOIN full_item_return fir
  ON ar.i_item_sk = fir.item_sk
WHERE ar.d_year BETWEEN 1999 AND 2001
  AND ar.total_return_amount > 1000
  AND demo.hd_buy_potential = '500-1000'
  AND demo.ib_upper_bound <= 120000
GROUP BY ar.i_category
ORDER BY sum_return_amount DESC
LIMIT 100
