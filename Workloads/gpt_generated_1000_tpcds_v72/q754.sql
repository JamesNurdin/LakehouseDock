WITH returns_filtered AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
        i.i_item_desc,
        i.i_product_name,
        REGEXP_EXTRACT(i.i_product_name, '(\\d{3})', 1) AS product_code
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE i.i_item_desc LIKE '%Metal%'
      AND REGEXP_LIKE(i.i_product_name, '\\d{3}')
),
agg_returns AS (
    SELECT
        ib_lower_bound,
        ib_upper_bound,
        city_state,
        product_code,
        COUNT(*) AS return_cnt,
        AVG(cr_return_amount) AS avg_return_amount,
        SUM(cr_net_loss) AS total_net_loss
    FROM returns_filtered
    GROUP BY ib_lower_bound, ib_upper_bound, city_state, product_code
    HAVING COUNT(*) > 5
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    city_state,
    product_code,
    return_cnt,
    avg_return_amount,
    total_net_loss,
    ROW_NUMBER() OVER (
        PARTITION BY ib_lower_bound, ib_upper_bound
        ORDER BY avg_return_amount DESC
    ) AS rank_within_income_band
FROM agg_returns
ORDER BY ib_lower_bound, rank_within_income_band
LIMIT 100
