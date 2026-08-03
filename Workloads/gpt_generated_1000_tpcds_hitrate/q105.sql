WITH sales_returns AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_net_profit,
        wr.wr_reason_sk,
        r.r_reason_desc,
        wr.wr_return_amt,
        wr.wr_return_tax
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450860 AND 2450900
        AND cs.cs_quantity > 1
        AND cs.cs_ext_discount_amt > 100.00
        AND hd.hd_income_band_sk IN (3, 6, 8, 10)
        AND hd.hd_buy_potential NOT LIKE '0-%'
        AND r.r_reason_desc <> 'Damaged'
        AND wr.wr_return_tax > 1.00
),
aggregated AS (
    SELECT
        hd_demo_sk,
        r_reason_desc,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS txn_count,
        AVG(cs_quantity) AS avg_quantity
    FROM sales_returns
    GROUP BY hd_demo_sk, r_reason_desc
    HAVING SUM(cs_net_profit) > 5000
        AND COUNT(*) >= 5
        AND SUM(wr_return_amt) > 1000
)
SELECT
    r_reason_desc,
    AVG(total_net_profit) AS avg_profit_per_demo,
    SUM(total_return_amt) AS total_return_amount,
    SUM(txn_count) AS total_transactions
FROM aggregated
GROUP BY r_reason_desc
ORDER BY avg_profit_per_demo DESC
LIMIT 100
