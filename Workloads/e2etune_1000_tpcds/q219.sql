WITH returns_by_band AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wr.wr_web_page_sk,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM web_returns wr
    JOIN income_band ib
        ON wr.wr_account_credit >= ib.ib_lower_bound
       AND wr.wr_account_credit <= ib.ib_upper_bound
    WHERE wr.wr_web_page_sk IN (2221, 1132, 1732)
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, wr.wr_web_page_sk
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    wr_web_page_sk,
    return_cnt,
    total_return_amt,
    total_net_loss,
    avg_return_qty,
    RANK() OVER (PARTITION BY wr_web_page_sk ORDER BY total_net_loss DESC) AS loss_rank
FROM returns_by_band
ORDER BY total_net_loss DESC, wr_web_page_sk
