WITH join_all AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_closed_date_sk,
        d1.d_year AS return_year,
        sr.sr_return_amt,
        sr.sr_refunded_cash,
        sr.sr_net_loss,
        cd1.cd_gender,
        ca1.ca_state AS cust_state,
        ca1.ca_country,
        hd1.hd_buy_potential,
        wp.wp_type,
        wp.wp_char_count,
        wr.wr_return_amt,
        wr.wr_account_credit
    FROM store_returns sr
    JOIN date_dim d1 ON sr.sr_returned_date_sk = d1.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd1 ON sr.sr_cdemo_sk = cd1.cd_demo_sk
    JOIN customer_address ca1 ON sr.sr_addr_sk = ca1.ca_address_sk
    JOIN household_demographics hd1 ON sr.sr_hdemo_sk = hd1.hd_demo_sk
    JOIN date_dim d3 ON d1.d_date_sk = d3.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d3.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d1.d_year = 2002
      AND s.s_state = 'CA'
      AND ca1.ca_country = 'United States'
      AND cd1.cd_gender = 'F'
      AND hd1.hd_buy_potential = '500-1000'
      AND sr.sr_return_amt > 50
      AND wp.wp_type = 'product'
      AND EXISTS (
          SELECT 1 FROM web_page wp2
          WHERE wp2.wp_web_page_sk = wp.wp_web_page_sk
            AND wp2.wp_char_count > 1000
      )
),
agg AS (
    SELECT
        s_store_sk,
        s_store_name,
        return_year,
        SUM(sr_return_amt) AS total_store_return,
        SUM(wr_return_amt) AS total_web_return,
        COUNT(*) AS txn_cnt,
        (
            SELECT MAX(d_closed.d_year)
            FROM date_dim d_closed
            WHERE d_closed.d_date_sk = s_closed_date_sk
        ) AS store_closed_year
    FROM join_all
    GROUP BY s_store_sk, s_store_name, return_year, s_closed_date_sk
)
SELECT
    s_store_name,
    store_closed_year,
    AVG(total_store_return + total_web_return) AS avg_total_return,
    SUM(txn_cnt) AS total_txns
FROM agg
GROUP BY s_store_name, store_closed_year
HAVING AVG(total_store_return + total_web_return) > 1000
ORDER BY avg_total_return DESC
LIMIT 100
