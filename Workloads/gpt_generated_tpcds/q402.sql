WITH returns_by_income AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_return_amount > 0
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
sales_by_income AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ws.ws_net_paid > 0
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    r.ib_lower_bound,
    r.ib_upper_bound,
    r.total_return_amount,
    r.total_net_loss,
    r.return_cnt,
    s.total_net_paid,
    s.total_net_profit,
    s.sales_cnt,
    (s.total_net_profit - r.total_net_loss) AS profit_loss_balance
FROM returns_by_income r
FULL OUTER JOIN sales_by_income s
    ON r.ib_lower_bound = s.ib_lower_bound
   AND r.ib_upper_bound = s.ib_upper_bound
ORDER BY r.ib_lower_bound
