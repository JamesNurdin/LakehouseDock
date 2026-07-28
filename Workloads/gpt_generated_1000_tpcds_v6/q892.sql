WITH base AS (
    SELECT
        d1.d_date,
        cc.cc_name,
        cc.cc_state,
        wsit.web_name,
        wsit.web_state,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ss.ss_ext_sales_price        AS store_sales_price,
        ws.ws_ext_sales_price        AS web_sales_price,
        cr.cr_return_amount,
        cr.cr_net_loss,
        r.r_reason_desc
    FROM catalog_sales cs
    JOIN date_dim d1
        ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d1.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d1.d_date_sk
    LEFT JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE d1.d_year = 2001
      AND cc.cc_state = 'TX'
      AND (r.r_reason_desc LIKE '%damage%' OR r.r_reason_desc IS NULL)
      AND cc.cc_name IN (
            SELECT name FROM (
                SELECT cc_inner.cc_name AS name FROM call_center cc_inner WHERE cc_inner.cc_state = 'TX'
                UNION
                SELECT wsit_inner.web_name AS name FROM web_site wsit_inner WHERE wsit_inner.web_state = 'CA'
            )
        )
)
SELECT
    base.d_date,
    base.cc_name,
    base.web_name,
    SUM(base.cs_ext_sales_price)               AS total_catalog_sales,
    SUM(base.store_sales_price)                AS total_store_sales,
    SUM(base.web_sales_price)                  AS total_web_sales,
    SUM(base.cs_net_profit)                    AS total_catalog_profit,
    CASE
        WHEN SUM(base.cs_net_profit) > (SELECT AVG(cs_net_profit) FROM catalog_sales) THEN 'Above Avg Profit'
        ELSE 'Below Avg Profit'
    END                                        AS profit_category
FROM base
GROUP BY
    base.d_date,
    base.cc_name,
    base.web_name
HAVING SUM(base.cs_ext_sales_price) > 100000
ORDER BY total_catalog_sales DESC
LIMIT 100
