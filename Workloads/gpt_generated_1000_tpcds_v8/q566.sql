WITH ss_hh AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_sales ss
    FULL OUTER JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ss.ss_quantity > 30 OR hd.hd_vehicle_count >= 2
),
high_sales_items AS (
    SELECT ss_item_sk
    FROM store_sales
    WHERE ss_net_profit > 1000
),
high_return_items AS (
    SELECT cr_item_sk
    FROM catalog_returns
    WHERE cr_return_amount > 500
),
items_not_returned AS (
    SELECT ss_item_sk
    FROM high_sales_items
    EXCEPT
    SELECT cr_item_sk
    FROM high_return_items
),
promo_active AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
),
promo_tv AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_channel_tv = 'Y'
),
promo_both AS (
    SELECT p_promo_sk
    FROM promo_active
    INTERSECT
    SELECT p_promo_sk
    FROM promo_tv
)
SELECT
    ss_hh.hd_income_band_sk AS income_band_sk,
    ss_hh.ib_lower_bound,
    ss_hh.ib_upper_bound,
    SUM(ss_hh.ss_quantity) AS total_quantity,
    SUM(ss_hh.ss_net_paid) AS total_net_paid
FROM ss_hh
WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = ss_hh.ss_item_sk
    )
GROUP BY ss_hh.hd_income_band_sk, ss_hh.ib_lower_bound, ss_hh.ib_upper_bound

UNION DISTINCT

SELECT
    NULL AS income_band_sk,
    NULL AS ib_lower_bound,
    NULL AS ib_upper_bound,
    COUNT(*) AS total_quantity,
    COALESCE(SUM(
        (SELECT ss2.ss_net_paid
         FROM store_sales ss2
         WHERE ss2.ss_item_sk = i.ss_item_sk)
    ), 0) AS total_net_paid
FROM items_not_returned i
WHERE i.ss_item_sk IN (SELECT p_promo_sk FROM promo_both)

ORDER BY total_net_paid DESC
LIMIT 100
