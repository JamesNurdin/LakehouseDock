WITH sales_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_location_type,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE hd.hd_buy_potential = '501-1000'
      AND hd.hd_dep_count >= 2
      AND hd.hd_vehicle_count > 0
      AND ca.ca_location_type = 'single family'
      AND ca.ca_gmt_offset = -7.00
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, ca.ca_location_type
),
returns_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_location_type,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE hd.hd_buy_potential = '501-1000'
      AND hd.hd_dep_count >= 2
      AND hd.hd_vehicle_count > 0
      AND ca.ca_location_type = 'single family'
      AND ca.ca_gmt_offset = -7.00
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, ca.ca_location_type
)
SELECT
    s.ib_income_band_sk,
    s.ib_lower_bound,
    s.ib_upper_bound,
    s.ca_location_type,
    s.total_sales,
    s.total_profit,
    s.distinct_orders,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.return_count, 0) AS return_count,
    (s.total_sales - COALESCE(r.total_return_amount, 0)) AS net_sales
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.ib_income_band_sk = r.ib_income_band_sk
   AND s.ib_lower_bound = r.ib_lower_bound
   AND s.ib_upper_bound = r.ib_upper_bound
   AND s.ca_location_type = r.ca_location_type
ORDER BY net_sales DESC
LIMIT 20
