WITH brand_returns AS (
    SELECT
        hd.hd_buy_potential,
        cd.cd_gender,
        i.i_brand,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_tax) AS avg_tax,
        MIN(wr.wr_return_amt) AS min_return,
        MAX(wr.wr_return_amt) AS max_return,
        SUM(CASE WHEN wr.wr_return_amt > 100 THEN 1 ELSE 0 END) AS high_value_cnt
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_brand_id IN (6012006, 2004002)
      AND hd.hd_buy_potential = '1001-5000'
      AND ib.ib_upper_bound <= 60000
    GROUP BY hd.hd_buy_potential, cd.cd_gender, i.i_brand
)
SELECT
    br.hd_buy_potential,
    br.cd_gender,
    br.i_brand,
    br.total_return_amt,
    br.return_cnt,
    br.avg_tax,
    br.high_value_cnt,
    RANK() OVER (PARTITION BY br.hd_buy_potential ORDER BY br.total_return_amt DESC) AS brand_rank,
    COALESCE(br.min_return, 0) AS min_return_amt,
    COALESCE(br.max_return, 0) AS max_return_amt,
    (SELECT AVG(total_return_amt) FROM brand_returns) AS overall_avg_return_amt
FROM brand_returns br
WHERE br.return_cnt > 10
ORDER BY br.total_return_amt DESC
LIMIT 100
