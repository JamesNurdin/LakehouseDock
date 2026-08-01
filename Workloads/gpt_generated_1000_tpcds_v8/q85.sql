WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cr.cr_return_amount,
        r.r_reason_desc AS cr_reason_desc,
        wsite.web_site_id,
        wsite.web_country,
        ib.ib_upper_bound,
        ws.ws_net_paid,
        ws.ws_ext_tax,
        wp.wp_type
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca_cs
        ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
    JOIN web_sales ws
        ON cs.cs_bill_cdemo_sk = ws.ws_bill_cdemo_sk
    JOIN customer_address ca_ws
        ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE ib.ib_upper_bound > 50000
      AND r.r_reason_desc LIKE '%duplicate%'
      AND wsite.web_country = 'United States'
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
),
agg_per_reason_site AS (
    SELECT
        cr_reason_desc,
        web_site_id,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM joined_data
    GROUP BY cr_reason_desc, web_site_id
)
SELECT
    cr_reason_desc,
    AVG(total_return_amount) AS avg_return_amount,
    SUM(distinct_orders) AS total_distinct_orders
FROM agg_per_reason_site
GROUP BY cr_reason_desc
HAVING AVG(total_return_amount) > 1000
ORDER BY avg_return_amount DESC
LIMIT 100
