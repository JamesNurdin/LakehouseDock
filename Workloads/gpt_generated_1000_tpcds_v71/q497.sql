WITH base AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        sm.sm_type AS ship_type,
        cc.cc_company_name AS company,
        ws_site.web_name AS site,
        s.s_state AS store_state,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND i.i_category = 'Electronics'
      AND sm.sm_type = 'AIR'
      AND cc.cc_company_name LIKE '%cally%'
      AND s.s_state = 'CA'
    GROUP BY
        d.d_year,
        i.i_category,
        sm.sm_type,
        cc.cc_company_name,
        ws_site.web_name,
        s.s_state
)
SELECT
    year,
    category,
    ship_type,
    company,
    site,
    store_state,
    total_catalog_sales,
    total_web_sales,
    total_returns,
    (total_catalog_profit + total_web_profit) - total_returns AS net_profit_after_returns,
    ((total_catalog_profit + total_web_profit) - total_returns) / NULLIF((total_catalog_sales + total_web_sales), 0) AS profit_margin
FROM base
WHERE (total_catalog_sales + total_web_sales) > 100000
  AND ((total_catalog_profit + total_web_profit) - total_returns) > 50000
ORDER BY profit_margin DESC
LIMIT 100
