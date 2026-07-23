WITH sales_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS sales_txn_cnt
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_item_sk
),
returns_agg AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        SUM(sr_refunded_cash) AS total_refunded_cash,
        SUM(sr_store_credit) AS total_store_credit,
        SUM(sr_net_loss) AS total_net_loss
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
)
SELECT
    D.d_year,
    D.d_month_seq,
    SA.ss_item_sk,
    SA.total_sales,
    SA.total_profit,
    RA.total_refunded_cash,
    CC.cc_market_manager,
    WP.wp_url,
    CASE
        WHEN SA.total_profit > 1000 THEN 'High Profit'
        WHEN SA.total_profit BETWEEN 0 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    RANK() OVER (PARTITION BY D.d_year, D.d_month_seq ORDER BY SA.total_sales DESC) AS sales_rank
FROM sales_agg SA
JOIN date_dim D ON SA.ss_sold_date_sk = D.d_date_sk
LEFT JOIN returns_agg RA ON RA.sr_returned_date_sk = D.d_date_sk AND RA.sr_item_sk = SA.ss_item_sk
JOIN catalog_returns CR ON CR.cr_returned_date_sk = D.d_date_sk
JOIN call_center CC ON CR.cr_call_center_sk = CC.cc_call_center_sk
JOIN web_page WP ON WP.wp_creation_date_sk = D.d_date_sk
WHERE D.d_year = 2000
  AND D.d_moy IN (3, 5, 7)
  AND CC.cc_state = 'CA'
  AND WP.wp_link_count > 10
  AND WP.wp_max_ad_count <= 2
  AND CR.cr_return_amount > 50
ORDER BY D.d_year, D.d_month_seq, sales_rank
LIMIT 100
