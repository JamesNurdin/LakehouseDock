WITH store_agg AS (
    SELECT
        ca.ca_state AS state,
        hd.hd_income_band_sk AS income_band,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        SUM(sr.sr_fee) AS total_fee
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_returned_date_sk >= 2450000
    GROUP BY ca.ca_state, hd.hd_income_band_sk
),
web_agg AS (
    SELECT
        ca.ca_state AS state,
        hd.hd_income_band_sk AS income_band,
        COUNT(DISTINCT wr.wr_refunded_customer_sk) AS distinct_customers,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        SUM(wr.wr_fee) AS total_fee
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_returned_date_sk >= 2450000
    GROUP BY ca.ca_state, hd.hd_income_band_sk
)
SELECT
    s.state,
    s.income_band,
    s.distinct_customers AS store_distinct_customers,
    w.distinct_customers AS web_distinct_customers,
    s.total_return_amt AS store_total_return_amt,
    w.total_return_amt AS web_total_return_amt,
    s.total_net_loss AS store_total_net_loss,
    w.total_net_loss AS web_total_net_loss,
    s.avg_return_qty AS store_avg_return_qty,
    w.avg_return_qty AS web_avg_return_qty,
    (s.total_net_loss - w.total_net_loss) AS net_loss_diff
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.state = w.state AND s.income_band = w.income_band
WHERE (s.total_return_amt IS NOT NULL OR w.total_return_amt IS NOT NULL)
ORDER BY net_loss_diff DESC
LIMIT 100
