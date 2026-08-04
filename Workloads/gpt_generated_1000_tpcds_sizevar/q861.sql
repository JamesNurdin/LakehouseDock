WITH intersect_orders AS (
    SELECT ws_order_number FROM web_sales WHERE ws_quantity > 10
    INTERSECT
    SELECT ws_order_number FROM web_sales WHERE ws_net_profit > 1000
),
base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        sm_cs.sm_carrier AS cs_carrier,
        sm_ws.sm_carrier AS ws_carrier,
        w_cs.w_warehouse_id,
        w_ws.w_state AS ws_state,
        t_cs.t_hour AS cs_hour,
        t_ws.t_hour AS ws_hour,
        cc.cc_name,
        cp.cp_department,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit,
        ws.ws_web_site_sk,
        web_site.web_name,
        ca.ca_city,
        ca.ca_location_type,
        (SELECT COALESCE(SUM(wr2.wr_return_amt), 0)
         FROM web_returns wr2
         WHERE wr2.wr_order_number = ws.ws_order_number) AS total_return_amt,
        ARRAY[sm_cs.sm_code, sm_ws.sm_code] AS carrier_codes
    FROM catalog_sales cs
    FULL OUTER JOIN web_sales ws
        ON cs.cs_item_sk = ws.ws_item_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk AND ws.ws_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cs
        ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse w_cs
        ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    JOIN warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN web_site
        ON ws.ws_web_site_sk = web_site.web_site_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    WHERE
        sm_cs.sm_carrier = 'USPS'
        AND i.i_category = 'Sports'
        AND t_cs.t_hour BETWEEN 8 AND 12
        AND w_ws.w_state = 'CA'
        AND cc.cc_state = 'CA'
        AND ws.ws_quantity > 5
        AND cs.cs_order_number IN (SELECT ws_order_number FROM intersect_orders)
)
SELECT
    base.cs_order_number,
    base.i_item_id,
    base.i_category,
    base.cs_quantity,
    base.ws_quantity,
    base.cs_net_paid,
    base.ws_net_paid,
    base.total_return_amt,
    base.cs_carrier,
    base.ws_carrier,
    carrier_code,
    ROW_NUMBER() OVER (PARTITION BY base.ws_web_site_sk ORDER BY base.ws_net_paid DESC) AS rn_site,
    DENSE_RANK() OVER (ORDER BY base.total_return_amt DESC) AS dr_total_return
FROM base
CROSS JOIN UNNEST(base.carrier_codes) AS t(carrier_code)
WHERE carrier_code IS NOT NULL
ORDER BY base.cs_order_number
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
