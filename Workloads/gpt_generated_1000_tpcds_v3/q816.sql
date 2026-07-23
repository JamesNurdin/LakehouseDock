WITH joined_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cc.cc_name,
        cc.cc_country,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wr.wr_return_amt,
        wp.wp_url,
        wp.wp_type
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
)
SELECT
    cs_sold_date_sk,
    cs_order_number,
    cc_name,
    cp_catalog_number,
    cp_catalog_page_number,
    ib_lower_bound,
    ib_upper_bound,
    CASE 
        WHEN cs_net_profit > 500 THEN 'High'
        WHEN cs_net_profit > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    cs_net_profit,
    SUM(cs_net_profit) OVER (
        PARTITION BY cc_name
        ORDER BY cs_net_profit DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit,
    ROW_NUMBER() OVER (
        PARTITION BY cc_name
        ORDER BY cs_net_profit DESC
    ) AS profit_rank,
    COUNT(wr_return_amt) OVER (PARTITION BY cc_name) AS return_count
FROM joined_data
WHERE
    cc_country = 'United States'
    AND cp_catalog_number IN (2, 3, 4)
    AND ib_upper_bound <= 120000
    AND cs_quantity >= 2
    AND cs_sales_price > 10
ORDER BY profit_rank, cs_sold_date_sk
LIMIT 100
