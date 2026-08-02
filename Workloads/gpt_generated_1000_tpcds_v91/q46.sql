WITH sales_sample AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        ss.ss_sold_date_sk,
        dd.d_year,
        dd.d_month_seq,
        ss.ss_store_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cc.cc_call_center_sk,
        cc.cc_company_name,
        cc.cc_state,
        wp.wp_type,
        sr.sr_net_loss,
        cr.cr_return_amount,
        cr.cr_fee,
        r.r_reason_desc
    FROM
        sales_sample ss
        JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN store_returns sr ON ss.ss_item_sk = sr.sr_item_sk
            AND ss.ss_ticket_number = sr.sr_ticket_number
        LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = dd.d_date_sk
            AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN web_page wp ON wp.wp_creation_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 1911
        AND ib.ib_upper_bound > 50000
        AND cc.cc_state = 'CA'
        AND wp.wp_type = 'Home'
        AND r.r_reason_desc IS NOT NULL
),
aggregated AS (
    SELECT
        d_year,
        ss_store_sk,
        hd_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        cc_call_center_sk,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(sr_net_loss) AS total_net_loss,
        AVG(cr_fee) AS avg_return_fee,
        COUNT(*) AS transaction_count
    FROM joined
    GROUP BY
        d_year,
        ss_store_sk,
        hd_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        cc_call_center_sk
    HAVING SUM(ss_net_profit) > 0
)
SELECT
    d_year,
    ss_store_sk,
    hd_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_net_profit,
    total_net_loss,
    avg_return_fee,
    transaction_count,
    SUM(total_net_profit) OVER (PARTITION BY d_year) AS total_year_profit,
    (SELECT MAX(cr2.cr_fee)
     FROM catalog_returns cr2
     WHERE cr2.cr_call_center_sk = aggregated.cc_call_center_sk) AS max_center_fee,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 100
