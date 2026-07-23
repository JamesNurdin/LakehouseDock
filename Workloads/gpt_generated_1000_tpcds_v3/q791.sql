WITH cs_agg AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_page_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_net_profit) AS avg_profit,
        hd_bill.hd_income_band_sk AS bill_income_band_sk,
        ib_bill.ib_lower_bound AS bill_income_lower,
        ib_bill.ib_upper_bound AS bill_income_upper
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib_bill
        ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib_ship
        ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    GROUP BY
        cp.cp_department,
        cp.cp_catalog_page_id,
        hd_bill.hd_income_band_sk,
        ib_bill.ib_lower_bound,
        ib_bill.ib_upper_bound
),

sr_agg AS (
    SELECT
        s.s_store_name,
        s.s_state,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        hd_ret.hd_income_band_sk AS ret_income_band_sk,
        ib_ret.ib_lower_bound AS ret_income_lower,
        ib_ret.ib_upper_bound AS ret_income_upper
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd_ret
        ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
    JOIN income_band ib_ret
        ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
    JOIN customer_address ca_ret
        ON sr.sr_addr_sk = ca_ret.ca_address_sk
    GROUP BY
        s.s_store_name,
        s.s_state,
        hd_ret.hd_income_band_sk,
        ib_ret.ib_lower_bound,
        ib_ret.ib_upper_bound
)

SELECT
    cs_agg.cp_department,
    cs_agg.cp_catalog_page_id,
    cs_agg.total_sales,
    cs_agg.total_quantity,
    cs_agg.avg_profit,
    cs_agg.bill_income_upper,
    sr_agg.s_store_name,
    sr_agg.s_state,
    sr_agg.total_return_amount,
    sr_agg.total_return_qty,
    sr_agg.ret_income_lower,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS global_max_income_upper
FROM cs_agg
CROSS JOIN sr_agg
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr_filter
    WHERE sr_filter.sr_net_loss > 0
)
ORDER BY cs_agg.total_sales DESC
LIMIT 100
