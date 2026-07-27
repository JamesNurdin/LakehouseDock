WITH distinct_items AS (
    SELECT DISTINCT i_item_sk,
                    i_brand_id,
                    i_brand,
                    i_size
    FROM item
    WHERE i_brand_id = 8007005
      AND i_size = 'medium'
),
agg_returns AS (
    SELECT
        d.d_year,
        di.i_brand,
        cd.cd_gender,
        hd.hd_buy_potential,
        SUM(sr.sr_return_amt)               AS total_return_amt,
        AVG(sr.sr_return_quantity)           AS avg_return_qty,
        COUNT(*)                              AS return_cnt,
        MIN(sr.sr_return_ship_cost)          AS min_ship_cost,
        MAX(sr.sr_return_ship_cost)          AS max_ship_cost
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN distinct_items di
        ON sr.sr_item_sk = di.i_item_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk = 9
      AND sr.sr_return_ship_cost > 500
      AND sr.sr_return_amt > 0
    GROUP BY d.d_year, di.i_brand, cd.cd_gender, hd.hd_buy_potential
)
SELECT
    d_year,
    i_brand,
    cd_gender,
    hd_buy_potential,
    total_return_amt,
    avg_return_qty,
    return_cnt,
    min_ship_cost,
    max_ship_cost,
    SUM(total_return_amt) OVER (
        PARTITION BY i_brand
        ORDER BY d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_brand_return
FROM agg_returns
ORDER BY total_return_amt DESC
LIMIT 100
