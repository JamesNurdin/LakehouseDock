WITH sr_joined AS (
    SELECT
        i_s.i_brand AS brand,
        i_s.i_category AS category,
        hd_s.hd_buy_potential AS buy_potential,
        td_s.t_shift AS shift,
        sr.sr_return_amt AS return_amt,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    INNER JOIN time_dim td_s
        ON sr.sr_return_time_sk = td_s.t_time_sk
    INNER JOIN item i_s
        ON sr.sr_item_sk = i_s.i_item_sk
    INNER JOIN customer c_s
        ON sr.sr_customer_sk = c_s.c_customer_sk
    INNER JOIN household_demographics hd_s
        ON sr.sr_hdemo_sk = hd_s.hd_demo_sk
    INNER JOIN income_band ib_s
        ON hd_s.hd_income_band_sk = ib_s.ib_income_band_sk
    INNER JOIN household_demographics hd_current
        ON c_s.c_current_hdemo_sk = hd_current.hd_demo_sk
    WHERE EXISTS (
        SELECT 1
        FROM reason r_filter
        WHERE r_filter.r_reason_sk = sr.sr_reason_sk
          AND r_filter.r_reason_desc = 'Damaged'
    )
      AND i_s.i_brand_id IN (1002001, 2004002)
      AND hd_s.hd_buy_potential = '5001-10000'
      AND td_s.t_shift = 'first'
),
wr_joined AS (
    SELECT
        i_w.i_brand AS brand,
        i_w.i_category AS category,
        hd_refunded.hd_buy_potential AS buy_potential,
        td_w.t_shift AS shift,
        wr.wr_return_amt AS return_amt,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    INNER JOIN time_dim td_w
        ON wr.wr_returned_time_sk = td_w.t_time_sk
    INNER JOIN item i_w
        ON wr.wr_item_sk = i_w.i_item_sk
    INNER JOIN customer c_refunded
        ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    INNER JOIN customer c_returning
        ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
    INNER JOIN household_demographics hd_refunded
        ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    INNER JOIN household_demographics hd_returning
        ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    INNER JOIN reason r_web
        ON wr.wr_reason_sk = r_web.r_reason_sk
    INNER JOIN income_band ib_refunded
        ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
    INNER JOIN income_band ib_returning
        ON hd_returning.hd_income_band_sk = ib_returning.ib_income_band_sk
    WHERE i_w.i_class_id = 10
      AND td_w.t_sub_shift = 'morning'
),
combined AS (
    SELECT brand, category, buy_potential, shift, return_amt, net_loss FROM sr_joined
    UNION ALL
    SELECT brand, category, buy_potential, shift, return_amt, net_loss FROM wr_joined
),
aggregated AS (
    SELECT
        brand,
        category,
        buy_potential,
        shift,
        SUM(return_amt) AS total_return_amt,
        SUM(net_loss) AS total_net_loss
    FROM combined
    GROUP BY brand, category, buy_potential, shift
)
SELECT
    brand,
    category,
    buy_potential,
    shift,
    total_return_amt,
    total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY brand ORDER BY total_return_amt DESC) AS brand_rank
FROM aggregated
ORDER BY brand_rank
LIMIT 100
