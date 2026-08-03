WITH base AS (
    SELECT
        i.i_category AS category,
        sm.sm_type AS ship_type,
        ca_bill.ca_state AS state,
        ib.ib_lower_bound AS income_lower,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM
        catalog_sales cs
        JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
        JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        i.i_rec_start_date >= DATE '1999-01-01'
        AND i.i_rec_end_date <= DATE '2001-12-31'
        AND td.t_hour BETWEEN 8 AND 20
        AND ca_bill.ca_country = 'United States'
        AND sm.sm_carrier = 'UPS'
    GROUP BY CUBE (i.i_category, sm.sm_type, ca_bill.ca_state, ib.ib_lower_bound)
)
SELECT
    category,
    ship_type,
    state,
    income_lower,
    SUM(total_sales) AS agg_sales,
    SUM(total_return_loss) AS agg_loss,
    SUM(distinct_customers) AS agg_customers
FROM base
WHERE total_sales > 1000
GROUP BY CUBE (category, ship_type, state, income_lower)
HAVING SUM(total_sales) > 5000

UNION DISTINCT

SELECT
    i.i_category AS category,
    sm.sm_type AS ship_type,
    ca.ca_state AS state,
    ib.ib_lower_bound AS income_lower,
    SUM(ws.ws_net_paid) AS agg_sales,
    SUM(ws.ws_net_profit) AS agg_profit,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS agg_customers
FROM (
    SELECT * FROM web_sales TABLESAMPLE BERNOULLI (10)
) ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    i.i_brand_id IN (51, 63)
    AND td.t_meal_time = 'Dinner'
    AND ca.ca_state IN ('CA', 'NY', 'TX')
    AND wp.wp_type = 'content'
    AND sm.sm_type = 'AIR'
GROUP BY CUBE (i.i_category, sm.sm_type, ca.ca_state, ib.ib_lower_bound)
