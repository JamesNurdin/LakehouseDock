WITH sales_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COUNT(*) AS sales_cnt,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_quantity >= 5
      AND cs.cs_ext_discount_amt > 500.00
    GROUP BY cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
    HAVING SUM(cs.cs_net_profit) > 20000
),
returns_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt,
        AVG(sr.sr_fee) AS avg_return_fee
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_return_quantity > 0
    GROUP BY cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    s.cd_gender,
    s.cd_marital_status,
    s.ib_lower_bound,
    s.ib_upper_bound,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_contribution,
    s.sales_cnt,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    s.avg_discount,
    COALESCE(r.avg_return_fee, 0) AS avg_return_fee,
    RANK() OVER (ORDER BY (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cd_gender = r.cd_gender
   AND s.cd_marital_status = r.cd_marital_status
   AND s.ib_lower_bound = r.ib_lower_bound
   AND s.ib_upper_bound = r.ib_upper_bound
ORDER BY net_contribution DESC
LIMIT 50
