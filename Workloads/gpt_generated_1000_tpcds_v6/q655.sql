WITH high_income_demo AS (
    SELECT hd.hd_demo_sk
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 100000
)
SELECT
    d_year,
    sales_amount,
    profit,
    profit_category,
    sales_source
FROM (
    SELECT
        d.d_year,
        ss.ss_net_paid AS sales_amount,
        ss.ss_net_profit AS profit,
        CASE WHEN ss.ss_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        'Store' AS sales_source
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN high_income_demo hi ON hd.hd_demo_sk = hi.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA' AND d.d_year = 2001

    UNION ALL

    SELECT
        d.d_year,
        cs.cs_net_paid AS sales_amount,
        cs.cs_net_profit AS profit,
        CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        'Catalog' AS sales_source
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN high_income_demo hi ON hd.hd_demo_sk = hi.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'CA' AND d.d_year = 2001
) t
LIMIT 100
