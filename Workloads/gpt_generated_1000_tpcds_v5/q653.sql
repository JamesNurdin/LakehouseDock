/* Goal: Analyze store return performance by store, customer income band and product brand, and compute cumulative and ranking metrics over the aggregated return amounts. */
WITH base AS (
    SELECT
        s.s_store_name AS store_name,
        ib.ib_lower_bound AS lower_bound,
        ib.ib_upper_bound AS upper_bound,
        i.i_brand AS brand,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    /* First join to the item dimension */
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    /* Second join to the same item table under a different alias (unused in the projection, but adds a join clause) */
    JOIN item i_alt ON sr.sr_item_sk = i_alt.i_item_sk
    /* Join to household demographics */
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    /* Second join to household_demographics under a different alias */
    JOIN household_demographics hd_alt ON sr.sr_hdemo_sk = hd_alt.hd_demo_sk
    /* Join to store */
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    /* Second join to store under a different alias */
    JOIN store s_alt ON sr.sr_store_sk = s_alt.s_store_sk
    /* Join to income band through the first household_demographics alias */
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    /* Second join to income_band through the second household_demographics alias */
    JOIN income_band ib_alt ON hd_alt.hd_income_band_sk = ib_alt.ib_income_band_sk
    WHERE i.i_current_price > 10
    GROUP BY s.s_store_name, ib.ib_lower_bound, ib.ib_upper_bound, i.i_brand
)
SELECT
    store_name,
    lower_bound,
    upper_bound,
    brand,
    total_return_amt,
    return_cnt,
    SUM(total_return_amt) OVER (ORDER BY total_return_amt DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return,
    RANK() OVER (ORDER BY total_return_amt DESC) AS brand_store_rank
FROM base
ORDER BY total_return_amt DESC
LIMIT 100
