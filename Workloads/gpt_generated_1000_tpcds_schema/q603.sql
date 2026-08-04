WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_sold_date_sk,
        c.c_customer_id,
        cd.cd_gender,
        cc.cc_name,
        w.w_warehouse_name,
        cr.cr_return_amount,
        r.r_reason_desc,
        s.s_store_name,
        sr.sr_net_loss,
        ws.ws_net_paid,
        wp.wp_url,
        ca.hour_part
    FROM
        (SELECT * FROM catalog_sales TABLESAMPLE BERNOULLI (10)) cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                   AND cr.cr_item_sk = cs.cs_item_sk
        LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN LATERAL (
            SELECT v AS hour_part
            FROM UNNEST(split(cc.cc_hours, ',')) AS t(v)
        ) ca ON true
        LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
        LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        cc.cc_gmt_offset BETWEEN -5 AND 5
        AND cd.cd_dep_count >= 2
        AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451911
        AND cs.cs_net_profit > 0
        AND cc.cc_tax_percentage < 10
        AND c.c_birth_year BETWEEN 1950 AND 1970
        AND s.s_division_id = 1
        AND r.r_reason_desc LIKE '%price%'
)
SELECT
    base.c_customer_id,
    base.cd_gender,
    base.cc_name,
    base.w_warehouse_name,
    base.r_reason_desc,
    base.s_store_name,
    SUM(base.cs_net_profit) AS total_profit,
    AVG(base.cs_quantity) AS avg_quantity,
    SUM(base.cr_return_amount) AS total_return_amount,
    SUM(base.sr_net_loss) AS total_store_loss,
    SUM(base.ws_net_paid) AS total_web_paid,
    COUNT(DISTINCT base.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT base.hour_part) AS distinct_hours
FROM base
GROUP BY CUBE (
    base.c_customer_id,
    base.cd_gender,
    base.cc_name,
    base.w_warehouse_name,
    base.r_reason_desc,
    base.s_store_name
)
HAVING SUM(base.cs_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
