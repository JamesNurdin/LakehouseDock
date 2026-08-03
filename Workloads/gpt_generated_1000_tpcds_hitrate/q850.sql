WITH base AS (
    SELECT
        s.s_state,
        d.d_year,
        cs.cs_ext_sales_price,
        cs.cs_order_number,
        cs.cs_coupon_amt,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cp.cp_department,
        wp.wp_type,
        ws.ws_net_profit
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                       AND ws.ws_sold_time_sk = t.t_time_sk
                       AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
                       AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
                       AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                         AND sr.sr_return_time_sk = t.t_time_sk
                         AND sr.sr_cdemo_sk = cd.cd_demo_sk
                         AND sr.sr_hdemo_sk = hd.hd_demo_sk
                         AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND cs.cs_net_paid_inc_tax > 1000
      AND ib.ib_lower_bound >= 80000
      AND s.s_state = 'CA'
      AND EXISTS (
          SELECT 1 FROM store_returns sr2
          WHERE sr2.sr_store_sk = s.s_store_sk
            AND sr2.sr_returned_date_sk = d.d_date_sk
      )
),
aggregated AS (
    SELECT
        s_state,
        d_year,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS orders_cnt,
        AVG(cs_coupon_amt) AS avg_coupon,
        SUM(CASE WHEN hd_buy_potential = 'High' THEN cs_ext_sales_price ELSE 0 END) AS high_potential_sales
    FROM base
    GROUP BY GROUPING SETS (
        (s_state, d_year),
        (s_state),
        (d_year),
        ()
    )
)
SELECT
    s_state,
    d_year,
    total_sales,
    orders_cnt,
    avg_coupon,
    high_potential_sales,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_sales DESC) AS rn_state
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
