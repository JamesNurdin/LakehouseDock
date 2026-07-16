WITH returns_agg AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS cnt_returns,
        AVG(hd.hd_income_band_sk) AS avg_income_band_refunded
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY d.d_date, d.d_year, d.d_month_seq
),
sales_agg AS (
    SELECT
        d.d_date,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        COUNT(*) AS cnt_sales,
        AVG(hd2.hd_income_band_sk) AS avg_income_band_bill
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    GROUP BY d.d_date
),
store_agg AS (
    SELECT
        d.d_date,
        COUNT(*) AS closed_stores,
        MAX(s.s_floor_space) AS max_floor_space,
        AVG(s.s_tax_percentage) AS avg_tax_percentage
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_date
)
SELECT
    r.d_date,
    r.d_year,
    r.d_month_seq,
    r.total_return_loss,
    r.cnt_returns,
    s.total_sales_profit,
    s.cnt_sales,
    (s.total_sales_profit - r.total_return_loss) AS net_profit_minus_loss,
    r.avg_income_band_refunded,
    s.avg_income_band_bill,
    st.closed_stores,
    st.max_floor_space,
    st.avg_tax_percentage,
    SUM(s.total_sales_profit) OVER (
        PARTITION BY r.d_year
        ORDER BY r.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_year_sales_profit
FROM returns_agg r
JOIN sales_agg s ON r.d_date = s.d_date
JOIN store_agg st ON r.d_date = st.d_date
WHERE r.d_year = 2000
ORDER BY r.d_date
LIMIT 100
