WITH item_price_band AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        i.i_wholesale_cost,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM item i
    JOIN income_band ib
        ON i.i_current_price BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE i.i_current_price > 5.00
),
aggregated AS (
    SELECT
        ipb.ib_income_band_sk,
        ipb.ib_lower_bound,
        ipb.ib_upper_bound,
        ipb.i_brand,
        ipb.i_category,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_page_cnt,
        SUM(wp.wp_char_count) AS total_char_count,
        AVG(ipb.i_current_price) AS avg_item_price,
        SUM(ipb.i_wholesale_cost) AS total_wholesale_cost,
        COUNT(*) AS item_page_links
    FROM item_price_band ipb
    JOIN web_page wp
        ON ipb.i_item_id = wp.wp_web_page_id
    WHERE wp.wp_type = 'product'
      AND wp.wp_char_count > 0
    GROUP BY
        ipb.ib_income_band_sk,
        ipb.ib_lower_bound,
        ipb.ib_upper_bound,
        ipb.i_brand,
        ipb.i_category
    HAVING COUNT(*) >= 5
)
SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY a.ib_income_band_sk ORDER BY a.total_char_count DESC) AS rank_in_band
FROM aggregated a
ORDER BY a.total_char_count DESC
LIMIT 100
