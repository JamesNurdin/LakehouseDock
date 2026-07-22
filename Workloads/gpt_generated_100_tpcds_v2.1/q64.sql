WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_paid_inc_tax,
        cs.cs_ext_discount_amt,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        t.t_hour,
        t.t_am_pm,
        ca.ca_state,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ws.ws_net_paid,
        cr.cr_net_loss,
        wsit.web_name
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE
        t.t_hour = 16
        AND t.t_am_pm = 'PM'
        AND i.i_brand = 'Brand#23'
        AND i.i_category = 'Electronics'
        AND ca.ca_state = 'CA'
        AND ib.ib_lower_bound >= 50000
        AND hd.hd_vehicle_count >= 2
        AND wsit.web_name = 'SiteA'
)
SELECT
    i_brand,
    i_category,
    web_name,
    ca_state,
    t_hour,
    t_am_pm,
    SUM(cs_net_paid) AS total_sales,
    SUM(cs_net_paid_inc_tax) AS total_sales_inc_tax,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(cr_net_loss) AS total_return_loss,
    AVG(cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    MIN(i_current_price) AS min_price,
    MAX(i_current_price) AS max_price
FROM joined_data
GROUP BY
    i_brand,
    i_category,
    web_name,
    ca_state,
    t_hour,
    t_am_pm
ORDER BY total_sales DESC
LIMIT 100
