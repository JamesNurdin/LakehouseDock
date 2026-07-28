WITH base AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_store_credit,
        d.d_year,
        s.s_state,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wp.wp_link_count,
        wr.wr_net_loss,
        wr.wr_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_access_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND sr.sr_store_credit > 100.00
      AND wp.wp_link_count = 15
)
SELECT
    d_year,
    s_state,
    ib_lower_bound,
    ib_upper_bound,
    COUNT(DISTINCT sr_ticket_number) AS cnt_returns,
    SUM(sr_return_amt) AS total_store_return_amt,
    AVG(sr_store_credit) AS avg_store_credit,
    SUM(wr_net_loss) AS total_web_net_loss,
    MIN(wr_return_amt) AS min_web_return_amt,
    MAX(wr_return_amt) AS max_web_return_amt,
    (SELECT COUNT(*) FROM web_page wp_sub WHERE wp_sub.wp_type = 'article') AS total_article_pages
FROM base
GROUP BY
    d_year,
    s_state,
    ib_lower_bound,
    ib_upper_bound
ORDER BY
    total_store_return_amt DESC
LIMIT 100
