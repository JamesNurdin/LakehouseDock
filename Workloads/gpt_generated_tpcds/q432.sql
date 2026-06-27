WITH catalog AS (
    SELECT
        r.r_reason_desc,
        ca.ca_state,
        hd.hd_income_band_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
),
store AS (
    SELECT
        r.r_reason_desc,
        ca.ca_state,
        hd.hd_income_band_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
),
web AS (
    SELECT
        r.r_reason_desc,
        ca.ca_state,
        hd.hd_income_band_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
)
SELECT
    'catalog' AS return_channel,
    c.r_reason_desc,
    c.ca_state,
    c.hd_income_band_sk,
    SUM(c.cr_return_quantity) AS total_return_quantity,
    SUM(c.cr_return_amount) AS total_return_amount,
    SUM(c.cr_net_loss) AS total_net_loss,
    AVG(c.cr_return_amount) AS avg_return_amount
FROM catalog c
GROUP BY c.r_reason_desc, c.ca_state, c.hd_income_band_sk
UNION ALL
SELECT
    'store' AS return_channel,
    s.r_reason_desc,
    s.ca_state,
    s.hd_income_band_sk,
    SUM(s.sr_return_quantity) AS total_return_quantity,
    SUM(s.sr_return_amt) AS total_return_amount,
    SUM(s.sr_net_loss) AS total_net_loss,
    AVG(s.sr_return_amt) AS avg_return_amount
FROM store s
GROUP BY s.r_reason_desc, s.ca_state, s.hd_income_band_sk
UNION ALL
SELECT
    'web' AS return_channel,
    w.r_reason_desc,
    w.ca_state,
    w.hd_income_band_sk,
    SUM(w.wr_return_quantity) AS total_return_quantity,
    SUM(w.wr_return_amt) AS total_return_amount,
    SUM(w.wr_net_loss) AS total_net_loss,
    AVG(w.wr_return_amt) AS avg_return_amount
FROM web w
GROUP BY w.r_reason_desc, w.ca_state, w.hd_income_band_sk
ORDER BY return_channel, total_net_loss DESC
