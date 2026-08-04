WITH base AS (
    SELECT
        ss.ss_quantity,
        ss.ss_net_profit,
        cs.cs_net_paid,
        ws.ws_net_paid,
        s.s_state,
        s.s_store_sk AS store_sk,
        cc.cc_name,
        cc.cc_gmt_offset,
        r.r_reason_desc,
        c.c_customer_id,
        c.c_birth_year,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        w.w_warehouse_id
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_item_sk = sr.sr_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs
        ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
    JOIN web_sales ws
        ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
    WHERE cc.cc_gmt_offset = -5.00
      AND s.s_state = 'CA'
      AND c.c_birth_year BETWEEN 1960 AND 1970
      AND r.r_reason_desc LIKE '%damaged%'
      AND we.web_country = 'United States'
),
agg AS (
    SELECT
        s_state,
        cc_name,
        r_reason_desc,
        store_sk,
        COUNT(DISTINCT c_customer_id) AS uniq_customers,
        SUM(ss_quantity) AS total_quantity_sold,
        SUM(ss_net_profit) AS total_store_profit,
        SUM(cs_net_paid) AS total_catalog_paid,
        SUM(ws_net_paid) AS total_web_paid,
        AVG(ib_lower_bound) AS avg_income_lower
    FROM base
    GROUP BY s_state, cc_name, r_reason_desc, store_sk
)
SELECT
    a.s_state,
    a.cc_name,
    a.r_reason_desc,
    a.uniq_customers,
    a.total_quantity_sold,
    a.total_store_profit,
    a.total_catalog_paid,
    a.total_web_paid,
    a.avg_income_lower,
    (
        SELECT COUNT(*)
        FROM store_returns sr_sub
        WHERE sr_sub.sr_store_sk = a.store_sk
    ) AS store_return_count,
    ROW_NUMBER() OVER (ORDER BY a.total_store_profit DESC) AS profit_rank
FROM agg a
ORDER BY profit_rank
LIMIT 100
