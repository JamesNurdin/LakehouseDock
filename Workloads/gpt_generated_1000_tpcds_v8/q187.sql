WITH base AS (
    SELECT
        d.d_year,
        sm.sm_carrier,
        i.i_brand,
        i.i_item_id,
        cs.cs_net_paid,
        cs.cs_net_profit,
        wr.wr_return_amt,
        CASE WHEN cs.cs_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
        ib_l.ib_lower_bound,
        ib_l.ib_upper_bound
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    CROSS JOIN LATERAL (
        SELECT ib.ib_lower_bound, ib.ib_upper_bound
        FROM tpcds.income_band ib
        WHERE ib.ib_income_band_sk = hd_bill.hd_income_band_sk
    ) ib_l
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN tpcds.household_demographics hd_refund ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    WHERE d.d_year = 2001
      AND sm.sm_carrier = 'UPS'
      AND i.i_brand = 'Brand#12'
      AND ib_l.ib_upper_bound > 50000
      AND (wr.wr_return_amt IS NULL OR wr.wr_return_amt > 100)
),
agg AS (
    SELECT
        d_year,
        sm_carrier,
        i_brand,
        profit_flag,
        SUM(cs_net_paid) AS total_sales,
        SUM(wr_return_amt) AS total_returns,
        COUNT(DISTINCT cs_net_paid) AS distinct_sales_cnt,
        SUM(CASE WHEN cs_net_profit > 0 THEN cs_net_paid ELSE 0 END) AS profit_sales
    FROM base
    GROUP BY ROLLUP (d_year, sm_carrier, i_brand, profit_flag)
)
SELECT
    d_year,
    sm_carrier,
    i_brand,
    profit_flag,
    total_sales,
    total_returns,
    distinct_sales_cnt,
    profit_sales,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM agg
WHERE d_year IS NOT NULL
ORDER BY d_year, sm_carrier, i_brand, sales_rank
LIMIT 100
