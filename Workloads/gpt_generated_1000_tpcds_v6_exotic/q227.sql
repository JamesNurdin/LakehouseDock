WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_sales_price,
        ss.ss_net_profit,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_sold.d_date,
        cd.cd_gender,
        cd.cd_credit_rating,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        ca.ca_state,
        s.s_store_name,
        s.s_market_manager,
        s.s_company_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cc.cc_name,
        cc.cc_manager
    FROM store_sales ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d_sold.d_date_sk
)
SELECT
    sd.s_store_name,
    sd.d_year,
    sd.cd_gender,
    sd.hd_buy_potential,
    SUM(sd.ss_ext_sales_price) AS total_sales,
    AVG(sd.ss_sales_price) AS avg_unit_price,
    COUNT(*) AS transaction_count,
    MIN(sd.ss_sales_price) AS min_price,
    MAX(sd.ss_sales_price) AS max_price,
    SUM(CASE WHEN sd.ss_net_profit > 0 THEN 1 ELSE 0 END) AS profitable_txn,
    CASE
        WHEN SUM(sd.ss_net_profit) > 0 THEN 'Overall Profit'
        ELSE 'Overall Loss'
    END AS profit_status
FROM sales_data sd
WHERE
    sd.d_year = 2001
    AND sd.ca_state = 'CA'
    AND sd.cd_credit_rating = 'Low Risk'
    AND sd.ib_lower_bound >= 40000
    AND sd.s_market_manager = 'David Smith'
GROUP BY
    sd.s_store_name,
    sd.d_year,
    sd.cd_gender,
    sd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
