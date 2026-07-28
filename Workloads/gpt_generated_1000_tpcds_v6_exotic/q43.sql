SELECT
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    r.r_reason_desc,
    sr.sr_return_amt,
    sr.sr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY sr.sr_net_loss DESC) AS rn_store_loss_rank,
    RANK() OVER (ORDER BY sr.sr_return_amt DESC) AS overall_return_amt_rank
FROM store_returns sr
JOIN item i
  ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE i.i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
  AND i.i_units IN ('Box', 'Carton', 'Ton')
  AND s.s_gmt_offset >= -5
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = sr.sr_item_sk
          AND wr2.wr_returning_customer_sk = sr.sr_customer_sk
    )
ORDER BY overall_return_amt_rank, s.s_store_name
LIMIT 100
