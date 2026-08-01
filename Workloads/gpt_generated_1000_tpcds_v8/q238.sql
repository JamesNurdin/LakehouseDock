WITH base AS (
    SELECT
        i.i_category,
        i.i_brand,
        i.i_item_sk,
        cc.cc_company_name,
        cc.cc_state,
        ca.ca_state,
        cd.cd_gender,
        sm.sm_code,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_order_number,
        ws.ws_net_paid,
        ws.ws_ext_sales_price,
        ws.ws_ship_mode_sk,
        sr.sr_return_amt,
        ws.ws_item_sk
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    WHERE cc.cc_state = 'CA'
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
)
SELECT
    category,
    brand,
    company_name,
    ship_mode,
    SUM(net_paid) AS total_net_paid,
    SUM(ext_sales_price) AS total_sales,
    COUNT(*) AS txn_count,
    COUNT(DISTINCT code_char) AS distinct_code_chars,
    MAX(max_order) AS max_order_number
FROM (
    SELECT
        i_category AS category,
        i_brand AS brand,
        cc_company_name AS company_name,
        sm_code AS ship_mode,
        cs_net_paid + ws_net_paid - sr_return_amt AS net_paid,
        cs_ext_sales_price + ws_ext_sales_price - sr_return_amt AS ext_sales_price,
        cs_order_number,
        i_item_sk,
        -- LATERAL sub‑query to fetch the maximum order number for the same item
        max_order_sub.max_order,
        -- explode the ship mode code into its characters
        code_char
    FROM base
    CROSS JOIN LATERAL (
        SELECT MAX(ws2.ws_order_number) AS max_order
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = base.i_item_sk
    ) AS max_order_sub
    CROSS JOIN UNNEST(split(sm_code, '')) AS t(code_char)
) AS detailed
GROUP BY ROLLUP (category, brand, company_name, ship_mode)
HAVING SUM(net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
