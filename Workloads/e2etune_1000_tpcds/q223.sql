SELECT
    brand,
    price_band,
    state,
    distinct_items,
    avg_price,
    total_wholesale_cost,
    RANK() OVER (PARTITION BY price_band ORDER BY total_wholesale_cost DESC) AS brand_rank_in_band
FROM (
    SELECT
        i.i_brand AS brand,
        ib.ib_income_band_sk AS price_band,
        ws.web_state AS state,
        COUNT(DISTINCT i.i_item_id) AS distinct_items,
        AVG(i.i_current_price) AS avg_price,
        SUM(i.i_wholesale_cost) AS total_wholesale_cost
    FROM item i
    JOIN web_site ws ON i.i_brand_id = ws.web_mkt_id
    JOIN income_band ib ON i.i_current_price BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE i.i_rec_start_date >= DATE '2022-01-01'
      AND ws.web_country = 'United States'
      AND i.i_brand IN ('exportischolar #2', 'amalgamalg #1', 'brandbrand #4')
    GROUP BY i.i_brand, ib.ib_income_band_sk, ws.web_state
    HAVING COUNT(DISTINCT i.i_item_id) > 10
) t
ORDER BY price_band, brand_rank_in_band
