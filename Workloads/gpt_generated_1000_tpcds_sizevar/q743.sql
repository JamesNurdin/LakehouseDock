WITH base AS (
    SELECT
        d_cs.d_year,
        cc.cc_state,
        p.p_promo_name,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        AVG(cs.cs_net_profit) AS avg_catalog_profit,
        AVG(ws.ws_net_profit) AS avg_web_profit
    FROM
        catalog_sales cs
        JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN (
            SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
        ) inv ON inv.inv_date_sk = d_cs.d_date_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d_cs.d_date_sk
        JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                               AND wr.wr_returned_date_sk = d_cs.d_date_sk
        JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
        JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_returned_date_sk = d_cs.d_date_sk
        JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    WHERE
        d_cs.d_year = 2001
        AND cc.cc_state = 'CA'
        AND p.p_promo_name = 'Holiday Sale'
        AND NOT EXISTS (
            SELECT 1 FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cs.cs_order_number
        )
        AND NOT EXISTS (
            SELECT 1 FROM web_returns wr2
            WHERE wr2.wr_order_number = ws.ws_order_number
        )
    GROUP BY
        d_cs.d_year,
        cc.cc_state,
        p.p_promo_name
),
base2 AS (
    SELECT
        d_cs.d_year,
        cc.cc_state,
        p.p_promo_name,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        AVG(cs.cs_net_profit) AS avg_catalog_profit,
        AVG(ws.ws_net_profit) AS avg_web_profit
    FROM
        catalog_sales cs
        JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN (
            SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
        ) inv ON inv.inv_date_sk = d_cs.d_date_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d_cs.d_date_sk
        JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                               AND wr.wr_returned_date_sk = d_cs.d_date_sk
        JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
        JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_returned_date_sk = d_cs.d_date_sk
        JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    WHERE
        d_cs.d_year = 2002
        AND cc.cc_state = 'NY'
        AND p.p_promo_name = 'Clearance Sale'
        AND NOT EXISTS (
            SELECT 1 FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cs.cs_order_number
        )
        AND NOT EXISTS (
            SELECT 1 FROM web_returns wr2
            WHERE wr2.wr_order_number = ws.ws_order_number
        )
    GROUP BY
        d_cs.d_year,
        cc.cc_state,
        p.p_promo_name
)
SELECT *
FROM (
    SELECT * FROM base
    UNION
    SELECT * FROM base2
) AS u
ORDER BY total_net_paid DESC
OFFSET 0 LIMIT 100
