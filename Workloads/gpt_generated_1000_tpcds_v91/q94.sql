WITH high_profit_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_net_profit > 2000
),
joined_facts AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d.d_year,
        d.d_date,
        c.c_customer_id,
        c.c_birth_country,
        ca.ca_location_type,
        ib.ib_lower_bound,
        cp.cp_department,
        p.p_channel_tv,
        sm.sm_type,
        ws.ws_net_paid AS ws_net_paid,
        sr.sr_return_amt,
        ws_site.web_country
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
                                 AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
                             AND ws.ws_sold_date_sk = d.d_date_sk
                             AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE d.d_year = 2001
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND c.c_birth_country = 'United States'
      AND ib.ib_lower_bound >= 50000
      AND p.p_channel_tv = 'N'
      AND sm.sm_type = 'AIR'
      AND ws_site.web_country = 'United States'
      AND cs.cs_order_number NOT IN (SELECT cs_order_number FROM high_profit_orders)
),
agg_by_customer_year AS (
    SELECT
        c_customer_id,
        d_year,
        SUM(cs_net_paid) AS total_catalog_sales,
        SUM(COALESCE(sr_return_amt, 0)) AS total_returns,
        SUM(COALESCE(ws_net_paid, 0)) AS total_web_sales,
        COUNT(DISTINCT cs_order_number) AS num_orders
    FROM joined_facts
    GROUP BY c_customer_id, d_year
)
SELECT
    a.c_customer_id,
    a.d_year,
    a.total_catalog_sales,
    a.total_returns,
    a.total_web_sales,
    a.num_orders,
    (a.total_catalog_sales + a.total_web_sales - a.total_returns) AS net_sales,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_catalog_sales DESC) AS sales_rank,
    SUM(a.total_catalog_sales) OVER (PARTITION BY a.d_year) AS year_total_catalog_sales,
    (SELECT SUM(cs_net_profit) FROM catalog_sales WHERE cs_net_profit > 0) AS overall_total_profit
FROM agg_by_customer_year a
WHERE a.c_customer_id NOT IN (
    SELECT c.c_customer_id
    FROM customer c
    JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE cs.cs_net_profit > 5000
)
ORDER BY a.d_year, sales_rank
LIMIT 100
