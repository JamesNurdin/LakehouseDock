WITH cs_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cc.cc_name,
        cp.cp_type,
        c_bill.c_customer_id AS bill_customer_id,
        c_ship.c_customer_id AS ship_customer_id,
        hd_bill.hd_income_band_sk AS bill_income_band_sk,
        hd_ship.hd_income_band_sk AS ship_income_band_sk,
        c_bill.c_current_hdemo_sk AS bill_current_hdemo_sk,
        c_ship.c_current_hdemo_sk AS ship_current_hdemo_sk,
        cs.cs_bill_hdemo_sk AS bill_hdemo_sk,
        cs.cs_ship_hdemo_sk AS ship_hdemo_sk
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
),
aggregated AS (
    SELECT
        cs_base.cc_name,
        cs_base.cp_type,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs_base.cs_net_paid) AS total_net_paid,
        SUM(cs_base.cs_net_profit) AS total_net_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_loss,
        COUNT(DISTINCT cs_base.bill_customer_id) AS distinct_customers
    FROM cs_base
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = cs_base.cs_bill_customer_sk
       AND sr.sr_hdemo_sk = cs_base.bill_hdemo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = cs_base.cs_bill_customer_sk
       AND wr.wr_refunded_hdemo_sk = cs_base.bill_hdemo_sk
    JOIN household_demographics hd_current
        ON cs_base.bill_current_hdemo_sk = hd_current.hd_demo_sk
    JOIN income_band ib
        ON hd_current.hd_income_band_sk = ib.ib_income_band_sk
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr_check
        WHERE sr_check.sr_customer_sk = cs_base.cs_bill_customer_sk
          AND sr_check.sr_return_amt > 500
    )
    GROUP BY
        cs_base.cc_name,
        cs_base.cp_type,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    cc_name,
    cp_type,
    ib_lower_bound,
    ib_upper_bound,
    total_net_paid,
    total_net_profit,
    total_store_return_loss,
    total_web_return_loss,
    distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY ib_lower_bound ORDER BY total_net_paid DESC) AS rank_within_income_band
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 100
